const assert = require("node:assert/strict")
const model = require("./Model.js")

function taskTimestamp(date) {
  const pad = value => String(value).padStart(2, "0")
  return date.getUTCFullYear()
    + pad(date.getUTCMonth() + 1)
    + pad(date.getUTCDate()) + "T"
    + pad(date.getUTCHours())
    + pad(date.getUTCMinutes())
    + pad(date.getUTCSeconds()) + "Z"
}

const now = new Date(2026, 7, 19, 12, 0, 0)
const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000)
const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000)
const tasks = [
  { status: "pending", description: "ready", urgency: 5, uuid: "a", start: taskTimestamp(now) },
  { status: "pending", description: "today", urgency: 4, uuid: "b", due: taskTimestamp(now) },
  { status: "pending", description: "overdue", urgency: 3, uuid: "c", due: taskTimestamp(yesterday) },
  { status: "pending", description: "scheduled", urgency: 2, uuid: "d", scheduled: taskTimestamp(tomorrow) },
  { status: "pending", description: "blocked", urgency: 1, uuid: "e", depends: ["a"] },
  { status: "completed", description: "older done", end: taskTimestamp(yesterday), urgency: 99, uuid: "f" },
  { status: "completed", description: "newer done", end: taskTimestamp(now), urgency: 0, uuid: "g" }
]

const parsed = model.parseExport(JSON.stringify(tasks))
assert.equal(parsed.tasks.length, 5)
assert.deepEqual(parsed.tasks.map(task => task.uuid), ["a", "b", "c", "d", "e"])
assert.equal(parsed.error, "")
assert.deepEqual(model.filterTasks(parsed.tasks, "ready", now.getTime()).map(task => task.uuid), ["a", "b", "c"])
assert.deepEqual(model.filterTasks(parsed.tasks, "today", now.getTime()).map(task => task.uuid), ["b"])
assert.deepEqual(model.filterTasks(parsed.tasks, "overdue", now.getTime()).map(task => task.uuid), ["c"])
assert.equal(model.filterTasks(parsed.tasks, "all", now.getTime()).length, 5)
assert.equal(model.activeCount(parsed.tasks), 1)
assert.deepEqual(model.paginate([1, 2, 3, 4, 5], 1, 2), {
  tasks: [3, 4],
  start: 2,
  hasPrevious: true,
  hasNext: true
})
assert.deepEqual(model.paginate([1, 2, 3, 4, 5], 2, 2), {
  tasks: [5],
  start: 4,
  hasPrevious: true,
  hasNext: false
})
assert.equal(model.taskDateTime(taskTimestamp(now)), "2026-08-19T12:00")
assert.equal(model.formatLocalDateTime(model.parseLocalDateTime("2026-08-20T14:30")), "2026-08-20T14:30")
assert.equal(model.parseLocalDateTime("2026-02-30T12:00"), null)

const completed = model.parseCompletedExport(JSON.stringify(tasks))
assert.deepEqual(completed.tasks.map(task => task.uuid), ["g", "f"])
assert.equal(completed.error, "")

assert.equal(model.taskDetails({
  start: taskTimestamp(now),
  project: "Work",
  priority: "H",
  due: taskTimestamp(now),
  tags: ["quick"]
}), "active  ·  Work  ·  priority H  ·  due 2026-08-19  ·  +quick")

assert.deepEqual(model.buildEditModifiers({
  description: "Old",
  project: "Work",
  priority: "H",
  due: taskTimestamp(now)
}, {
  description: "New task",
  project: "",
  priority: "M",
  due: "tomorrow"
}), {
  args: ["description:New task", "project:", "priority:M", "due:tomorrow"],
  error: ""
})
assert.deepEqual(model.buildEditModifiers({
  description: "Same",
  due: taskTimestamp(now)
}, {
  description: "Same",
  due: model.taskDateTime(taskTimestamp(now))
}), {
  args: [],
  error: ""
})
assert.match(model.buildEditModifiers({}, { description: "" }).error, /required/)
assert.match(model.parseExport("not json").error, /invalid JSON/)
assert.match(model.parseCompletedExport("not json").error, /invalid JSON/)

console.log("taskwarrior model checks passed")
