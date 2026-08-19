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

  function focusDefault() {
    Qt.callLater(function() {
      if (!root.opened || !controller.taskAvailable || root.editing) return
      if (controller.currentFilter === "done") taskList.forceActiveFocus()
      else composer.focusInput()
    })
  }

  function setFilter(filter) {
    taskEditor.end()
    controller.setFilter(filter)
    Qt.callLater(function() {
      root.focusDefault()
    })
  }

  function startEdit(task) {
    if (!task || !task.uuid || controller.busy) return
    controller.clearError()
    taskEditor.begin(task)
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
      taskEditor.end()
    }
  }

  TaskwarriorController {
    id: controller
    onActionSucceeded: function(kind) {
      if (kind === "add") composer.clear()
      if (kind === "edit") root.cancelEdit()
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
    focusTarget: controller.currentFilter === "done" ? taskList : composer
    contentWidth: panel.fittedContentWidth(Style.space(440))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    Item {
      anchors.fill: parent
      Keys.onEscapePressed: root.editing ? root.cancelEdit() : root.close()

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
          visible: controller.taskAvailable && !root.editing
          anchors.horizontalCenter: parent.horizontalCenter
          options: controller.filterOptions
          value: controller.currentFilter
          foreground: root.foreground
          fontFamily: root.fontFamily
          onSelected: function(value) { root.setFilter(value) }
        }

        TaskComposer {
          id: composer
          visible: controller.taskAvailable && !root.editing && controller.currentFilter !== "done"
          width: parent.width
          busy: controller.busy
          foreground: root.foreground
          fontFamily: root.fontFamily
          onSubmitRequested: function(description) { controller.addTask(description) }
          onCloseRequested: root.close()
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

        BorderSurface {
          visible: root.editing && controller.errorText !== ""
          width: parent.width
          implicitHeight: editorError.implicitHeight + Style.space(12)
          color: Style.normalFillFor(root.urgent, Color.accent)
          borderSpec: Border.controlSpec("normal", root.urgent, Color.accent)
          radius: Style.cornerRadius

          Text {
            id: editorError
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Style.space(8)
            anchors.rightMargin: Style.space(8)
            text: controller.errorText
            color: root.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }

        TaskList {
          id: taskList
          visible: controller.taskAvailable && !root.editing
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
          foreground: root.foreground
          urgent: root.urgent
          fontFamily: root.fontFamily
          onPreviousPageRequested: controller.previousPage()
          onNextPageRequested: controller.nextPage()
          onTrackingRequested: function(task) { controller.toggleTracking(task) }
          onEditRequested: function(task) { root.startEdit(task) }
          onCompleteRequested: function(uuid) { controller.completeTask(uuid) }
        }
      }
    }
  }
}
