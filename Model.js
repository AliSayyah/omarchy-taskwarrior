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

function taskDateTimeLabel(value) {
  return taskDateTime(value).replace("T", " · ")
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

function isWaiting(task, now) {
  if (!task) return false
  var current = Number(now)
  var wait = parseTimestamp(task.wait)
  return task.status === "waiting"
    || (isFinite(wait) && wait > current)
}

function pendingIds(tasks) {
  var ids = {}
  for (var i = 0; i < tasks.length; i++) {
    if (tasks[i] && tasks[i].status === "pending" && tasks[i].uuid)
      ids[String(tasks[i].uuid)] = true
  }
  return ids
}

function hasPendingDependency(task, ids) {
  var dependencies = task && Array.isArray(task.depends) ? task.depends : []
  for (var i = 0; i < dependencies.length; i++)
    if (ids[String(dependencies[i])]) return true
  return false
}

function isBlocked(task, tasks) {
  return hasPendingDependency(task, pendingIds(Array.isArray(tasks) ? tasks : []))
}

function isReady(task, ids, now) {
  if (!task || task.status !== "pending") return false
  var scheduled = parseTimestamp(task.scheduled)
  var wait = parseTimestamp(task.wait)
  if ((isFinite(scheduled) && scheduled > now) || (isFinite(wait) && wait > now)) return false

  return !hasPendingDependency(task, ids)
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

function searchableText(task) {
  var item = task || {}
  var parts = [item.description, item.project]
  if (Array.isArray(item.tags)) parts = parts.concat(item.tags)
  if (Array.isArray(item.annotations)) {
    for (var i = 0; i < item.annotations.length; i++)
      parts.push(item.annotations[i] && item.annotations[i].description)
  }
  return parts.filter(function(value) { return value !== undefined && value !== null })
    .join(" ").toLowerCase()
}

function refineTasks(tasks, query, kind, value, pendingTasks, now) {
  var list = Array.isArray(tasks) ? tasks : []
  var terms = String(query || "").trim().toLowerCase().split(/\s+/)
    .filter(function(term) { return term !== "" })
  var filterKind = String(kind || "")
  var filterValue = String(value || "")
  var current = Number(now)
  var ids = pendingIds(Array.isArray(pendingTasks) ? pendingTasks : [])
  if (!isFinite(current)) current = Date.now()

  return list.filter(function(task) {
    var text = searchableText(task)
    for (var i = 0; i < terms.length; i++)
      if (text.indexOf(terms[i]) < 0) return false

    if (filterKind === "active") return !!task.start
    if (filterKind === "blocked") return hasPendingDependency(task, ids)
    if (filterKind === "waiting") return isWaiting(task, current)
    if (filterKind === "project") return String(task.project || "") === filterValue
    if (filterKind === "tag")
      return Array.isArray(task.tags) && task.tags.indexOf(filterValue) >= 0
    return true
  })
}

function uniqueValues(tasks, key) {
  var seen = {}
  var values = []
  var list = Array.isArray(tasks) ? tasks : []
  for (var i = 0; i < list.length; i++) {
    var candidates = key === "tags"
      ? (Array.isArray(list[i].tags) ? list[i].tags : [])
      : [list[i][key]]
    for (var j = 0; j < candidates.length; j++) {
      var value = String(candidates[j] || "").trim()
      if (value && !seen[value]) {
        seen[value] = true
        values.push(value)
      }
    }
  }
  return values.sort(function(left, right) { return left.localeCompare(right) })
}

function projectNames(tasks) {
  return uniqueValues(tasks, "project")
}

function tagNames(tasks) {
  return uniqueValues(tasks, "tags")
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

function normalizeTags(tags) {
  var result = []
  var seen = {}
  var values = Array.isArray(tags) ? tags : []
  for (var i = 0; i < values.length; i++) {
    var tag = String(values[i] || "").trim().replace(/^\+/, "")
    if (!tag || seen[tag]) continue
    if (/\s/.test(tag)) return { tags: [], error: "Tags cannot contain spaces" }
    seen[tag] = true
    result.push(tag)
  }
  return { tags: result, error: "" }
}

function buildAddArguments(draft) {
  var item = draft || {}
  var description = String(item.description || "").trim()
  var project = String(item.project || "").trim()
  var priority = String(item.priority || "").trim().toUpperCase()
  var due = String(item.due || "").trim()
  var normalized = normalizeTags(item.tags)

  if (!description) return { args: [], error: "Description is required" }
  if (["", "L", "M", "H"].indexOf(priority) < 0)
    return { args: [], error: "Priority must be low, medium, high, or none" }
  if (normalized.error) return { args: [], error: normalized.error }

  var args = ["add", description]
  if (project) args.push("project:" + project)
  if (priority) args.push("priority:" + priority)
  if (due) args.push("due:" + due)
  for (var i = 0; i < normalized.tags.length; i++) args.push("+" + normalized.tags[i])
  return { args: args, error: "" }
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
    taskDateTimeLabel: taskDateTimeLabel,
    parseLocalDateTime: parseLocalDateTime,
    formatLocalDateTime: formatLocalDateTime,
    isOverdue: isOverdue,
    isToday: isToday,
    isWaiting: isWaiting,
    isBlocked: isBlocked,
    filterTasks: filterTasks,
    refineTasks: refineTasks,
    projectNames: projectNames,
    tagNames: tagNames,
    activeCount: activeCount,
    paginate: paginate,
    taskDetails: taskDetails,
    buildAddArguments: buildAddArguments,
    buildEditModifiers: buildEditModifiers
  }
}
