const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")

const root = __dirname
const panel = fs.readFileSync(path.join(root, "Panel.qml"), "utf8")
const controller = fs.readFileSync(path.join(root, "TaskwarriorController.qml"), "utf8")
const components = [
  "TaskFilters.qml",
  "TaskComposer.qml",
  "TaskEditor.qml",
  "DateTimePicker.qml",
  "TaskList.qml",
  "TaskCard.qml",
  "TaskDetails.qml"
]

assert.ok(panel.split("\n").length < 350, "Panel.qml should remain a thin composition root")
assert.ok(!panel.includes("Process {"), "Taskwarrior processes belong in the controller")
assert.ok(controller.includes("Process {"), "Controller must own Taskwarrior processes")
for (const component of components)
  assert.ok(fs.existsSync(path.join(root, "components", component)), `missing ${component}`)

const taskList = fs.readFileSync(path.join(root, "components", "TaskList.qml"), "utf8")
assert.ok(taskList.includes("previousPageRequested"), "Task list must expose previous-page navigation")
assert.ok(taskList.includes("nextPageRequested"), "Task list must expose next-page navigation")
assert.ok(!taskList.includes("Flickable {"), "Task list pagination must not depend on scrolling")
assert.match(taskList, /enabled: root\.hasPrevious && !root\.loading/, "Previous must disable without a previous page")
assert.match(taskList, /enabled: root\.hasNext && !root\.loading/, "Next must disable without a next page")

const taskCard = fs.readFileSync(path.join(root, "components", "TaskCard.qml"), "utf8")
assert.ok(taskCard.includes("maximumLineCount: 2"), "Task cards must cap previews at two lines")
assert.ok(taskCard.includes("id: detailsButton"), "Every task card must expose the details action")
assert.ok(!taskCard.includes("detailsAvailable"), "Task details must not depend on truncation")
assert.ok(taskCard.includes("visible: root.hasMetadata"), "Metadata row visibility must derive from task data")
assert.ok(!taskCard.includes("priorityPill.visible || duePill.visible"), "Metadata visibility must not depend on hidden children")
assert.match(controller, /property int pageSize: 5/, "Two-line task cards must use five-item pages")

console.log("taskwarrior structure checks passed")
