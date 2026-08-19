import "Model.js" as Model
import QtQuick
import Quickshell.Io

Item {
  id: root

  property var allTasks: []
  property var completedTasks: []
  property string currentFilter: "ready"
  property string errorText: ""
  property string refreshError: ""
  property string completedError: ""
  property string completedRefreshError: ""
  property string actionError: ""
  property string actionKind: ""
  property bool taskAvailable: false
  property bool availabilityKnown: false
  property bool completedLoaded: false
  property bool completedHasMore: false
  property int completedFetchLimit: 50
  property int pageIndex: 0
  property int pageSize: 8
  property bool advanceAfterCompletedRefresh: false

  readonly property bool busy: actionProc.running
  readonly property bool installRunning: installProc.running
  readonly property bool completedLoading: completedRefreshProc.running
  readonly property var matchingTasks: currentFilter === "done"
    ? completedTasks
    : Model.filterTasks(allTasks, currentFilter, Date.now())
  readonly property var page: Model.paginate(matchingTasks, pageIndex, pageSize)
  readonly property int pageStart: page.start
  readonly property var tasks: page.tasks
  readonly property bool hasPrevious: page.hasPrevious
  readonly property bool hasNext: page.hasNext
    || (currentFilter === "done" && completedHasMore)
  readonly property string visibleError: currentFilter === "done" ? completedError : errorText
  readonly property int total: allTasks.length
  readonly property int readyCount: Model.filterTasks(allTasks, "ready", Date.now()).length
  readonly property int todayCount: Model.filterTasks(allTasks, "today", Date.now()).length
  readonly property int overdueCount: Model.filterTasks(allTasks, "overdue", Date.now()).length
  readonly property int activeCount: Model.activeCount(allTasks)
  readonly property var filterOptions: [
    { value: "ready", label: "Ready", count: readyCount },
    { value: "today", label: "Today", count: todayCount },
    { value: "overdue", label: "Overdue", count: overdueCount },
    { value: "all", label: "All", count: total },
    { value: "done", label: "Done", count: completedLoaded ? completedTasks.length : null }
  ]
  readonly property string barText: {
    var parts = []
    if (overdueCount > 0) parts.push("󰃰 " + overdueCount)
    if (activeCount > 0) parts.push("󰐊 " + activeCount)
    return parts.length ? parts.join("  ") : "󰄲 " + total
  }
  readonly property string barTooltip: {
    var text = total + (total === 1 ? " pending task" : " pending tasks")
    if (overdueCount > 0) text += " · " + overdueCount + " overdue"
    if (activeCount > 0) text += " · " + activeCount + " active"
    return text
  }

  signal actionSucceeded(string kind)

  visible: false
  width: 0
  height: 0

  function clearError() { errorText = "" }

  function checkAvailability() {
    if (!availabilityProc.running) availabilityProc.running = true
  }

  function installTaskwarrior() {
    if (installProc.running) return
    installProc.command = ["omarchy-launch-floating-terminal-with-presentation", "omarchy pkg add task"]
    installProc.running = true
  }

  function refresh() {
    if (!taskAvailable) return
    if (!refreshProc.running) {
      refreshError = ""
      refreshProc.running = true
    }
    if (currentFilter === "done") refreshCompleted()
  }

  function refreshCompleted() {
    if (!taskAvailable || completedRefreshProc.running) return
    completedRefreshError = ""
    completedRefreshProc.running = true
  }

  function setFilter(filter) {
    currentFilter = filter
    pageIndex = 0
    advanceAfterCompletedRefresh = false
    if (filter === "done") refreshCompleted()
  }

  function previousPage() {
    if (pageIndex > 0) pageIndex--
  }

  function nextPage() {
    if (pageStart + pageSize < matchingTasks.length) {
      pageIndex++
      return
    }
    if (currentFilter === "done" && completedLoaded && completedHasMore && !completedRefreshProc.running) {
      completedFetchLimit += 50
      advanceAfterCompletedRefresh = true
      refreshCompleted()
    }
  }

  function clampPage() {
    var maximum = Math.max(0, Math.ceil(matchingTasks.length / pageSize) - 1)
    if (pageIndex > maximum && !(currentFilter === "done" && completedHasMore)) pageIndex = maximum
  }

  function addTask(description) {
    description = String(description || "").trim()
    if (!description) return
    runAction(["task", "rc.confirmation=off", "rc.verbose=nothing", "add", description], "add")
  }

  function completeTask(uuid) {
    if (!uuid) return
    runAction(["task", "rc.confirmation=off", "rc.verbose=nothing", String(uuid), "done"], "done")
  }

  function toggleTracking(task) {
    if (!task || !task.uuid) return
    runAction([
      "task", "rc.confirmation=off", "rc.verbose=nothing", String(task.uuid),
      task.start ? "stop" : "start"
    ], task.start ? "stop" : "start")
  }

  function saveEdit(task, draft) {
    if (!task || !task.uuid || busy) return
    var result = Model.buildEditModifiers(task, draft)
    if (result.error) {
      errorText = result.error
      return
    }
    if (!result.args.length) {
      actionSucceeded("edit")
      return
    }
    var command = [
      "task", "rc.confirmation=off", "rc.verbose=nothing",
      String(task.uuid), "modify"
    ]
    for (var i = 0; i < result.args.length; i++) command.push(result.args[i])
    runAction(command, "edit")
  }

  function runAction(command, kind) {
    if (busy) return
    actionKind = kind
    actionError = ""
    errorText = ""
    actionProc.command = command
    actionProc.running = true
  }

  function applyExport(raw) {
    var result = Model.parseExport(raw)
    allTasks = result.tasks
    errorText = result.error
    if (currentFilter !== "done") clampPage()
  }

  function applyCompletedExport(raw) {
    var result = Model.parseCompletedExport(raw)
    completedTasks = result.tasks
    completedLoaded = result.error === ""
    completedHasMore = result.error === "" && result.tasks.length >= completedFetchLimit
    completedError = result.error
    if (advanceAfterCompletedRefresh) {
      advanceAfterCompletedRefresh = false
      if (pageStart + pageSize < result.tasks.length) pageIndex++
    }
    clampPage()
  }

  Process {
    id: availabilityProc
    command: ["bash", "-c", "command -v task >/dev/null 2>&1"]
    onExited: function(exitCode) {
      root.availabilityKnown = true
      root.taskAvailable = exitCode === 0
      if (root.taskAvailable) {
        root.refresh()
      } else {
        root.allTasks = []
        root.completedTasks = []
        root.completedLoaded = false
        root.errorText = ""
      }
    }
  }

  Process {
    id: installProc
    onExited: root.checkAvailability()
  }

  Process {
    id: refreshProc
    command: ["task", "rc.verbose=nothing", "status:pending", "export"]
    onExited: function(exitCode) {
      if (exitCode !== 0) root.errorText = root.refreshError || "Could not read Taskwarrior tasks"
    }
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyExport(text) }
    stderr: StdioCollector { waitForEnd: true; onStreamFinished: root.refreshError = String(text || "").trim() }
  }

  Process {
    id: completedRefreshProc
    command: [
      "task", "rc.verbose=nothing", "rc.report.completed.sort=end-", "status:completed",
      "limit:" + root.completedFetchLimit, "export", "completed"
    ]
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.completedLoaded = false
        root.completedError = root.completedRefreshError || "Could not read completed Taskwarrior tasks"
      }
    }
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyCompletedExport(text) }
    stderr: StdioCollector { waitForEnd: true; onStreamFinished: root.completedRefreshError = String(text || "").trim() }
  }

  Process {
    id: actionProc
    onExited: function(exitCode) {
      if (exitCode === 0) {
        if (root.actionKind === "done") root.completedLoaded = false
        root.actionSucceeded(root.actionKind)
        Qt.callLater(root.refresh)
      } else {
        root.errorText = root.actionError || "Taskwarrior command failed"
      }
    }
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { waitForEnd: true; onStreamFinished: root.actionError = String(text || "").trim() }
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkAvailability()
  }
}
