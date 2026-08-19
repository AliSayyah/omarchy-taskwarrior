import "components"
import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root

  readonly property color foreground: bar ? bar.barForeground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool editing: taskEditor.active
  readonly property bool viewingDetails: taskDetails.active
  readonly property bool composing: composer.expanded
  readonly property bool focusedMode: editing || viewingDetails || composing

  function focusDefault() {
    Qt.callLater(function() {
      if (!root.opened || !controller.taskAvailable || root.focusedMode) return
      if (controller.currentFilter === "done") taskList.forceActiveFocus()
      else composer.focusInput()
    })
  }

  function setFilter(filter) {
    composer.collapse()
    taskSearch.collapse()
    taskEditor.end()
    taskDetails.end()
    controller.setFilter(filter)
    Qt.callLater(function() {
      root.focusDefault()
    })
  }

  function startEdit(task) {
    if (!task || !task.uuid || controller.busy) return
    taskDetails.end()
    controller.clearError()
    taskEditor.begin(task)
  }

  function showDetails(task) {
    if (!task || !task.uuid) return
    taskEditor.end()
    controller.clearError()
    taskDetails.begin(task)
  }

  function closeDetails() {
    taskDetails.end()
    controller.clearError()
    focusDefault()
  }

  function cancelEdit() {
    taskEditor.end()
    controller.clearError()
    focusDefault()
  }

  moduleName: "taskwarrior"
  ipcTarget: "taskwarrior"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    if (opened) {
      controller.checkAvailability()
      focusDefault()
    } else {
      composer.collapse()
      taskSearch.collapse()
      taskEditor.end()
      taskDetails.end()
    }
  }

  TaskwarriorController {
    id: controller
    onActionSucceeded: function(kind) {
      if (kind === "add") composer.clear()
      if (kind === "edit") root.cancelEdit()
      else if (root.viewingDetails) root.closeDetails()
      else root.focusDefault()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: controller.overdueCount > 0
    text: !controller.availabilityKnown
      ? "󰄲 …"
      : (controller.taskAvailable ? controller.barText : "󰄲 !")
    tooltipText: !controller.availabilityKnown
      ? "Checking for Taskwarrior"
      : (controller.taskAvailable ? controller.barTooltip : "Taskwarrior is not installed")
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) {
        if (controller.taskAvailable) controller.refresh()
        else controller.checkAvailability()
      } else {
        root.toggle()
      }
    }
  }

  Component {
    id: taskIcon
    Text {
      text: controller.activeCount > 0 ? "󰐊" : "󰄲"
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.title
    }
  }

  Component {
    id: headerStatus
    Row {
      spacing: Style.space(6)
      StatusPill {
        visible: controller.activeCount > 0
        text: "󰐊 " + controller.activeCount
        tint: Color.accent
        fontFamily: root.fontFamily
      }
      StatusPill {
        visible: controller.overdueCount > 0
        text: "󰃰 " + controller.overdueCount
        tint: root.urgent
        fontFamily: root.fontFamily
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: root.editing
      ? taskEditor
      : (root.viewingDetails ? taskDetails : (controller.currentFilter === "done" ? taskList : composer))
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    Item {
      anchors.fill: parent
      Keys.onEscapePressed: root.editing
        ? root.cancelEdit()
        : (root.viewingDetails ? root.closeDetails() : root.close())

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          iconComponent: taskIcon
          title: "Taskwarrior"
          meta: !controller.availabilityKnown
            ? "Checking installation"
            : (controller.taskAvailable
              ? controller.total + (controller.total === 1 ? " pending task" : " pending tasks")
              : "Not installed")
          trailingControl: controller.taskAvailable
            && (controller.activeCount > 0 || controller.overdueCount > 0) ? headerStatus : null
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        Text {
          visible: !controller.availabilityKnown
          width: parent.width
          text: "Checking for the task command…"
          color: Qt.darker(root.foreground, 1.4)
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }

        Column {
          visible: controller.availabilityKnown && !controller.taskAvailable
          width: parent.width
          spacing: Style.space(8)

          Text {
            width: parent.width
            text: "Taskwarrior is required to use this plugin."
            color: Qt.darker(root.foreground, 1.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }
          Button {
            text: controller.installRunning ? "Installer open…" : "Install Taskwarrior"
            foreground: root.foreground
            fontFamily: root.fontFamily
            enabled: !controller.installRunning
            focusable: true
            onClicked: controller.installTaskwarrior()
          }
          Text {
            text: "Runs: omarchy pkg add task"
            color: Qt.darker(root.foreground, 1.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        TaskFilters {
          visible: controller.taskAvailable && !root.focusedMode
          anchors.horizontalCenter: parent.horizontalCenter
          options: controller.filterOptions
          value: controller.currentFilter
          foreground: root.foreground
          fontFamily: root.fontFamily
          onSelected: function(value) { root.setFilter(value) }
        }

        TaskComposer {
          id: composer
          visible: controller.taskAvailable && !root.editing && !root.viewingDetails
            && controller.currentFilter !== "done"
          width: parent.width
          busy: controller.busy
          projectSuggestions: controller.projectSuggestions
          tagSuggestions: controller.tagSuggestions
          foreground: root.foreground
          fontFamily: root.fontFamily
          onSubmitRequested: function(draft) { controller.addTask(draft) }
          onCloseRequested: root.close()
        }

        TaskSearch {
          id: taskSearch
          visible: controller.taskAvailable && !root.focusedMode
          width: parent.width
          query: controller.searchText
          filterKind: controller.taskFilterKind
          filterValue: controller.taskFilterValue
          projects: controller.projectSuggestions
          tags: controller.tagSuggestions
          completed: controller.currentFilter === "done"
          foreground: root.foreground
          fontFamily: root.fontFamily
          onSearchChanged: function(text) { controller.setSearch(text) }
          onFilterChanged: function(kind, value) { controller.setTaskFilter(kind, value) }
          onCloseRequested: root.close()
        }

        TaskActionNotice {
          width: parent.width
          task: controller.taskAvailable && !root.focusedMode ? controller.restorableTask : null
          busy: controller.busy
          foreground: root.foreground
          fontFamily: root.fontFamily
          onRestoreRequested: function(uuid) { controller.restoreTask(uuid) }
          onDismissRequested: controller.dismissRestore()
        }

        TaskEditor {
          id: taskEditor
          width: parent.width
          busy: controller.busy
          foreground: root.foreground
          fontFamily: root.fontFamily
          onSaveRequested: function(task, draft) { controller.saveEdit(task, draft) }
          onCancelRequested: root.cancelEdit()
        }

        TaskDetails {
          id: taskDetails
          width: parent.width
          busy: controller.busy
          foreground: root.foreground
          urgent: root.urgent
          fontFamily: root.fontFamily
          onCloseRequested: root.closeDetails()
          onTrackingRequested: function(task) { controller.toggleTracking(task) }
          onEditRequested: function(task) { root.startEdit(task) }
          onCompleteRequested: function(uuid) { controller.completeTask(uuid) }
          onRestoreRequested: function(uuid) { controller.restoreTask(uuid) }
        }

        TaskErrorNotice {
          width: parent.width
          text: root.focusedMode ? controller.errorText : ""
          urgent: root.urgent
          fontFamily: root.fontFamily
        }

        TaskList {
          id: taskList
          visible: controller.taskAvailable && !root.focusedMode
          width: parent.width
          tasks: controller.tasks
          totalCount: controller.matchingTasks.length
          pageIndex: controller.pageIndex
          pageSize: controller.pageSize
          filter: controller.currentFilter
          errorText: controller.visibleError
          busy: controller.busy
          loading: controller.currentFilter === "done" && controller.completedLoading
          hasPrevious: controller.hasPrevious
          hasNext: controller.hasNext
          remoteHasMore: controller.currentFilter === "done" && controller.completedHasMore
          constrained: controller.constrained
          foreground: root.foreground
          urgent: root.urgent
          fontFamily: root.fontFamily
          onPreviousPageRequested: controller.previousPage()
          onNextPageRequested: controller.nextPage()
          onDetailsRequested: function(task) { root.showDetails(task) }
          onTrackingRequested: function(task) { controller.toggleTracking(task) }
          onEditRequested: function(task) { root.startEdit(task) }
          onCompleteRequested: function(uuid) { controller.completeTask(uuid) }
          onRestoreRequested: function(uuid) { controller.restoreTask(uuid) }
        }
      }
    }
  }
}
