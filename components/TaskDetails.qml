import "../Model.js" as Model
import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root

  property bool active: false
  property bool busy: false
  property var task: null
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family
  readonly property bool completed: task && task.status === "completed"
  readonly property bool overdue: task && !completed && Model.isOverdue(task, Date.now())
  readonly property var annotations: task && Array.isArray(task.annotations) ? task.annotations : []

  signal closeRequested()
  signal trackingRequested(var task)
  signal editRequested(var task)
  signal completeRequested(string uuid)
  signal restoreRequested(string uuid)

  function begin(item) {
    task = item
    active = !!item
    Qt.callLater(forceActiveFocus)
  }

  function end() {
    active = false
    task = null
  }

  function priorityLabel() {
    if (!task) return ""
    if (task.priority === "H") return "HIGH"
    if (task.priority === "M") return "MEDIUM"
    if (task.priority === "L") return "LOW"
    return ""
  }

  visible: active || opacity > 0
  opacity: active ? 1 : 0
  spacing: Style.space(10)
  focus: active

  Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
  Keys.onEscapePressed: root.closeRequested()

  Item {
    width: parent.width
    implicitHeight: Math.max(backButton.implicitHeight, heading.implicitHeight)

    PanelActionButton {
      id: backButton
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      iconText: "󰅁"
      tooltipText: "Back to tasks"
      foreground: root.foreground
      fontFamily: root.fontFamily
      focusable: true
      onClicked: root.closeRequested()
    }

    PanelSectionHeader {
      id: heading
      anchors.left: backButton.right
      anchors.leftMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      text: "TASK DETAILS"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }
  }

  BorderSurface {
    width: parent.width
    implicitHeight: descriptionText.implicitHeight + Style.space(20)
    color: Style.normalFillFor(root.foreground, Color.accent)
    borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
    radius: Style.cornerRadius

    Text {
      id: descriptionText
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      text: root.task ? String(root.task.description || "Untitled task") : ""
      color: root.completed ? Qt.darker(root.foreground, 1.3) : root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.subtitle
      font.bold: root.task && (root.task.start || root.task.priority === "H")
      font.strikeout: root.completed
      wrapMode: Text.Wrap
    }
  }

  Flow {
    width: parent.width
    height: childrenRect.height
    spacing: Style.space(6)

    StatusPill {
      text: root.completed ? "COMPLETED" : (root.task && root.task.start ? "ACTIVE" : "PENDING")
      tint: root.completed
        ? Qt.darker(root.foreground, 1.35)
        : (root.task && root.task.start ? Color.accent : root.foreground)
      fontFamily: root.fontFamily
    }

    StatusPill {
      visible: root.priorityLabel() !== ""
      text: root.priorityLabel()
      tint: root.task && root.task.priority === "H"
        ? root.urgent
        : (root.task && root.task.priority === "M" ? Color.accent : root.foreground)
      fontFamily: root.fontFamily
    }

    StatusPill {
      visible: root.task && !!root.task.project
      text: "󰏗 " + (root.task ? String(root.task.project || "") : "")
      tint: root.foreground
      fontFamily: root.fontFamily
    }

    StatusPill {
      visible: root.task && (root.completed ? !!root.task.end : !!root.task.due)
      text: root.completed
        ? "󰄬 " + Model.taskDateTimeLabel(root.task ? root.task.end : "")
        : (root.overdue ? "󰃰 " : "󰥔 ") + Model.taskDateTimeLabel(root.task ? root.task.due : "")
      tint: root.overdue ? root.urgent : root.foreground
      fontFamily: root.fontFamily
    }

    StatusPill {
      visible: root.task && Array.isArray(root.task.tags) && root.task.tags.length > 0
      text: root.task && Array.isArray(root.task.tags)
        ? root.task.tags.map(function(tag) { return "+" + tag }).join(" ") : ""
      tint: root.foreground
      fontFamily: root.fontFamily
    }
  }

  Column {
    visible: root.annotations.length > 0
    width: parent.width
    spacing: Style.space(6)

    PanelSectionHeader {
      text: "ANNOTATIONS"
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Repeater {
      model: root.annotations
      delegate: BorderSurface {
        required property var modelData
        width: parent.width
        implicitHeight: annotationText.implicitHeight + Style.space(14)
        color: "transparent"
        borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
        radius: Style.cornerRadius

        Text {
          id: annotationText
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.leftMargin: Style.space(8)
          anchors.rightMargin: Style.space(8)
          text: String(modelData.description || "")
          color: Qt.darker(root.foreground, 1.25)
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.Wrap
        }
      }
    }
  }

  Row {
    visible: !root.completed
    width: parent.width
    spacing: Style.space(8)

    Item {
      width: parent.width - trackingButton.width - editButton.width - doneButton.width - parent.spacing * 3
      height: 1
    }

    Button {
      id: trackingButton
      text: root.task && root.task.start ? "Stop" : "Start"
      iconText: root.task && root.task.start ? "󰓛" : "󰐊"
      foreground: root.foreground
      fontFamily: root.fontFamily
      bordered: true
      focusable: true
      enabled: !root.busy
      onClicked: root.trackingRequested(root.task)
    }

    Button {
      id: editButton
      text: "Edit"
      iconText: "󰏫"
      foreground: root.foreground
      fontFamily: root.fontFamily
      bordered: true
      focusable: true
      enabled: !root.busy
      onClicked: root.editRequested(root.task)
    }

    Button {
      id: doneButton
      text: "Complete"
      iconText: "󰄬"
      foreground: root.foreground
      fontFamily: root.fontFamily
      selected: true
      bordered: true
      focusable: true
      enabled: !root.busy
      onClicked: root.completeRequested(String(root.task ? root.task.uuid || "" : ""))
    }
  }

  Row {
    visible: root.completed
    width: parent.width
    spacing: Style.space(8)

    Item { width: parent.width - restoreButton.width; height: 1 }

    Button {
      id: restoreButton
      text: root.busy ? "Restoring…" : "Restore"
      iconText: "󰕌"
      foreground: root.foreground
      fontFamily: root.fontFamily
      selected: true
      bordered: true
      focusable: true
      enabled: !root.busy
      onClicked: root.restoreRequested(String(root.task ? root.task.uuid || "" : ""))
    }
  }
}
