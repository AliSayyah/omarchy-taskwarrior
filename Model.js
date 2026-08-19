function parseStatusExport(raw, status) {
  var data
  try {
    data = JSON.parse(String(raw || "[]"))
  } catch (error) {
    return { tasks: [], error: "Taskwarrior returned invalid JSON" }
  }

  if (!Array.isArray(data))
    return { tasks: [], error: "Taskwarrior returned invalid JSON" }

  return {
    tasks: data.filter(function(task) {
      return task && task.status === status
    }),
    error: ""
  }
}

function parseExport(raw) {
  var result = parseStatusExport(raw, "pending")
  if (result.error) return result
  result.tasks.sort(function(left, right) {
    return Number(right.urgency || 0) - Number(left.urgency || 0)
  })
  return result
}

function parseCompletedExport(raw) {
  var result = parseStatusExport(raw, "completed")
  if (result.error) return result
  result.tasks.sort(function(left, right) {
    return Number(parseTimestamp(right.end) || 0) - Number(parseTimestamp(left.end) || 0)
  })
  return result
}

function parseTimestamp(value) {
  var match = String(value || "").match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$/)
  if (!match) return NaN
  return Date.UTC(
    Number(match[1]), Number(match[2]) - 1, Number(match[3]),
    Number(match[4]), Number(match[5]), Number(match[6]))
}

function pad(value) {
  return String(value).padStart(2, "0")
}

function localDateKey(timestamp) {
  var date = new Date(timestamp)
  if (isNaN(date.getTime())) return ""
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
}

function localDateTimeKey(timestamp) {
  var date = new Date(timestamp)
  if (isNaN(date.getTime())) return ""
  return localDateKey(timestamp) + "T" + pad(date.getHours()) + ":" + pad(date.getMinutes())
}

function taskDate(value) {
  return localDateKey(parseTimestamp(value))
}

function taskDateTime(value) {
  return localDateTimeKey(parseTimestamp(value))
}

function parseLocalDateTime(value) {
  var match = String(value || "").match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/)
  if (!match) return null
  var date = new Date(
    Number(match[1]), Number(match[2]) - 1, Number(match[3]),
    Number(match[4]), Number(match[5]), 0, 0)
  if (date.getFullYear() !== Number(match[1])
      || date.getMonth() !== Number(match[2]) - 1
      || date.getDate() !== Number(match[3])
      || date.getHours() !== Number(match[4])
      || date.getMinutes() !== Number(match[5])) return null
  return date
}

function formatLocalDateTime(value) {
  var date = value instanceof Date ? value : new Date(value)
  return isNaN(date.getTime()) ? "" : localDateTimeKey(date.getTime())
}

function isOverdue(task, now) {
  var due = parseTimestamp((task || {}).due)
  return isFinite(due) && due < Number(now)
}

function isToday(task, now) {
  var due = parseTimestamp((task || {}).due)
  return isFinite(due) && localDateKey(due) === localDateKey(Number(now))
}

function pendingIds(tasks) {
  var ids = {}
  for (var i = 0; i < tasks.length; i++) {
    if (tasks[i] && tasks[i].status === "pending" && tasks[i].uuid)
      ids[String(tasks[i].uuid)] = true
  }
  return ids
}

function isReady(task, ids, now) {
  if (!task || task.status !== "pending") return false
  var scheduled = parseTimestamp(task.scheduled)
  var wait = parseTimestamp(task.wait)
  if ((isFinite(scheduled) && scheduled > now) || (isFinite(wait) && wait > now)) return false

  var dependencies = Array.isArray(task.depends) ? task.depends : []
  for (var i = 0; i < dependencies.length; i++)
    if (ids[String(dependencies[i])]) return false
  return true
}

function filterTasks(tasks, filter, now) {
  var list = Array.isArray(tasks) ? tasks : []
  var current = Number(now)
  if (!isFinite(current)) current = Date.now()
  if (filter === "all") return list.slice()
  if (filter === "today") return list.filter(function(task) { return isToday(task, current) })
  if (filter === "overdue") return list.filter(function(task) { return isOverdue(task, current) })

  var ids = pendingIds(list)
  return list.filter(function(task) { return isReady(task, ids, current) })
}

function activeCount(tasks) {
  return (Array.isArray(tasks) ? tasks : []).filter(function(task) {
    return !!(task && task.start)
  }).length
}

function paginate(tasks, pageIndex, pageSize) {
  var list = Array.isArray(tasks) ? tasks : []
  var size = Math.max(1, parseInt(pageSize, 10) || 8)
  var index = Math.max(0, parseInt(pageIndex, 10) || 0)
  var start = index * size
  return {
    tasks: list.slice(start, start + size),
    start: start,
    hasPrevious: index > 0,
    hasNext: start + size < list.length
  }
}

function taskDetails(task) {
  var item = task || {}
  var details = []
  if (item.start) details.push("active")
  if (item.project) details.push(String(item.project))
  if (item.priority) details.push("priority " + item.priority)
  if (item.due) details.push("due " + taskDate(item.due))
  if (item.scheduled) details.push("scheduled " + taskDate(item.scheduled))
  if (Array.isArray(item.tags) && item.tags.length)
    details.push(item.tags.map(function(tag) { return "+" + tag }).join(" "))
  return details.join("  ·  ")
}

function buildEditModifiers(original, edited) {
  var before = original || {}
  var after = edited || {}
  var description = String(after.description || "").trim()
  var project = String(after.project || "").trim()
  var priority = String(after.priority || "").trim().toUpperCase()
  var due = String(after.due || "").trim()

  if (!description) return { args: [], error: "Description is required" }
  if (["", "L", "M", "H"].indexOf(priority) < 0)
    return { args: [], error: "Priority must be low, medium, high, or none" }

  var args = []
  if (description !== String(before.description || "").trim())
    args.push("description:" + description)
  if (project !== String(before.project || "").trim())
    args.push("project:" + project)
  if (priority !== String(before.priority || "").trim().toUpperCase())
    args.push("priority:" + priority)
  if (due !== taskDateTime(before.due))
    args.push("due:" + due)
  return { args: args, error: "" }
}

if (typeof module !== "undefined") {
  module.exports = {
    parseExport: parseExport,
    parseCompletedExport: parseCompletedExport,
    parseTimestamp: parseTimestamp,
    localDateKey: localDateKey,
    localDateTimeKey: localDateTimeKey,
    taskDate: taskDate,
    taskDateTime: taskDateTime,
    parseLocalDateTime: parseLocalDateTime,
    formatLocalDateTime: formatLocalDateTime,
    isOverdue: isOverdue,
    isToday: isToday,
    filterTasks: filterTasks,
    activeCount: activeCount,
    paginate: paginate,
    taskDetails: taskDetails,
    buildEditModifiers: buildEditModifiers
  }
}
