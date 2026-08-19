import "../Model.js" as Model
import QtQuick
import qs.Commons
import qs.Ui

CursorSurface {
  id: root

  property var task: ({})
  property bool busy: false
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family
  readonly property bool completed: task.status === "completed"
  readonly property bool overdue: !completed && Model.isOverdue(task, Date.now())
  readonly property string contextText: {
    var parts = []
    if (task.project) parts.push(String(task.project))
    if (task.scheduled) parts.push("scheduled " + Model.taskDate(task.scheduled))
    if (Array.isArray(task.tags) && task.tags.length)
      parts.push(task.tags.map(function(tag) { return "+" + tag }).join(" "))
    return parts.join("  ·  ")
  }
  readonly property bool actionsHot: !completed && (rowHover.hovered
    || trackingButton.activeFocus || editButton.activeFocus || doneButton.activeFocus)

  signal trackingRequested(var task)
  signal editRequested(var task)
  signal completeRequested(string uuid)

  implicitHeight: taskRow.implicitHeight + Style.space(16)
  bordered: true
  hasCursor: actionsHot
  current: !completed && !!task.start

  HoverHandler { id: rowHover }

  Rectangle {
    visible: !!root.task.start || root.completed
    anchors.left: parent.left
    anchors.leftMargin: Style.space(5)
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(3)
    height: parent.height - Style.space(14)
    color: root.completed ? Qt.darker(root.foreground, 1.45) : Color.accent
    radius: Style.cornerRadius
  }

  Item {
    id: taskRow
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(14)
    anchors.rightMargin: Style.space(10)
    implicitHeight: Math.max(labels.implicitHeight, actionRow.implicitHeight)

    Column {
      id: labels
      anchors.left: parent.left
      anchors.right: actionRow.left
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(5)

      Text {
        width: parent.width
        text: root.task.description || "Untitled task"
        color: root.completed ? Qt.darker(root.foreground, 1.35) : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: !root.completed && !!root.task.start
        font.strikeout: root.completed
        elide: Text.ElideRight
      }

      Item {
        width: parent.width
        visible: priorityPill.visible || root.contextText !== "" || dueText.visible
        height: visible ? Math.max(priorityPill.implicitHeight, contextLabel.implicitHeight, dueText.implicitHeight) : 0

        StatusPill {
          id: priorityPill
          visible: !!root.task.priority
          width: visible ? implicitWidth : 0
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: String(root.task.priority || "")
          tint: root.task.priority === "H"
            ? root.urgent
            : (root.task.priority === "M" ? Color.accent : Qt.darker(root.foreground, 1.35))
          fontFamily: root.fontFamily
        }

        Text {
          id: contextLabel
          anchors.left: priorityPill.right
          anchors.leftMargin: priorityPill.visible ? Style.space(7) : 0
          anchors.right: dueText.left
          anchors.rightMargin: dueText.visible ? Style.space(8) : 0
          anchors.verticalCenter: parent.verticalCenter
          text: root.contextText
          color: Qt.darker(root.foreground, 1.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        Text {
          id: dueText
          visible: root.completed ? !!root.task.end : !!root.task.due
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: root.completed
            ? "󰄬 " + Model.taskDate(root.task.end)
            : (root.overdue ? "󰃰 " : "󰥔 ") + Model.taskDate(root.task.due)
          color: root.overdue ? root.urgent : Qt.darker(root.foreground, 1.35)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: root.overdue
        }
      }
    }

    Row {
      id: actionRow
      visible: !root.completed
      width: visible ? implicitWidth : 0
      height: visible ? implicitHeight : 0
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(3)
      opacity: root.actionsHot ? 1 : 0.34

      PanelActionButton {
        id: trackingButton
        iconText: root.task.start ? "󰓛" : "󰐊"
        tooltipText: root.task.start ? "Stop task" : "Start task"
        foreground: root.foreground
        hoverColor: Color.accent
        fontFamily: root.fontFamily
        enabled: !root.busy
        focusable: true
        onClicked: root.trackingRequested(root.task)
      }

      PanelActionButton {
        id: editButton
        iconText: "󰏫"
        tooltipText: "Edit task"
        foreground: root.foreground
        fontFamily: root.fontFamily
        enabled: !root.busy
        focusable: true
        onClicked: root.editRequested(root.task)
      }

      PanelActionButton {
        id: doneButton
        iconText: "󰄬"
        tooltipText: "Complete task"
        foreground: root.foreground
        hoverColor: Color.accent
        fontFamily: root.fontFamily
        enabled: !root.busy
        focusable: true
        onClicked: root.completeRequested(String(root.task.uuid || ""))
      }

      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
  }
}
