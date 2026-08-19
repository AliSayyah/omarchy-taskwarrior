import "../Model.js" as Model
import QtQuick
import QtQuick.Layouts
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
  readonly property string priorityLabel: {
    if (task.priority === "H") return "HIGH"
    if (task.priority === "M") return "MEDIUM"
    if (task.priority === "L") return "LOW"
    return ""
  }
  readonly property color priorityColor: task.priority === "H"
    ? urgent
    : (task.priority === "M" ? Color.accent : Qt.darker(foreground, 1.3))
  readonly property string contextText: {
    var parts = []
    if (task.project) parts.push(String(task.project))
    if (task.scheduled) parts.push("scheduled " + Model.taskDate(task.scheduled))
    if (Array.isArray(task.tags) && task.tags.length)
      parts.push(task.tags.map(function(tag) { return "+" + tag }).join(" "))
    return parts.join("  ·  ")
  }
  readonly property bool hasMetadata: priorityLabel !== "" || contextText !== ""
    || (completed ? !!task.end : !!task.due)
  readonly property string stateGlyph: completed ? "󰄬" : (task.start ? "󰐊" : (overdue ? "󰃰" : "󰄱"))
  readonly property color stateColor: completed
    ? Qt.darker(foreground, 1.45)
    : (task.start ? Color.accent : (overdue ? urgent : Qt.darker(foreground, 1.35)))
  readonly property bool actionsHot: rowHover.hovered || detailsButton.activeFocus
    || trackingButton.activeFocus || editButton.activeFocus || doneButton.activeFocus
    || restoreButton.activeFocus

  signal detailsRequested(var task)
  signal trackingRequested(var task)
  signal editRequested(var task)
  signal completeRequested(string uuid)
  signal restoreRequested(string uuid)

  implicitHeight: contentRow.implicitHeight + Style.space(18)
  bordered: true
  hasCursor: actionsHot
  current: !completed && !!task.start
  color: hasCursor
    ? fill
    : (current ? currentFill : Style.normalFillFor(foreground, accent))

  HoverHandler { id: rowHover }

  Rectangle {
    visible: !!root.task.start || root.overdue || root.completed
    anchors.left: parent.left
    anchors.leftMargin: Style.space(4)
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(3)
    height: parent.height - Style.space(12)
    color: root.stateColor
    radius: Style.cornerRadius
  }

  RowLayout {
    id: contentRow
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(12)
    anchors.rightMargin: Style.space(9)
    spacing: Style.space(10)

    Text {
      text: root.stateGlyph
      color: root.stateColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.iconLarge
      Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.space(5)

      Text {
        id: descriptionText
        Layout.fillWidth: true
        text: root.task.description || "Untitled task"
        color: root.completed ? Qt.darker(root.foreground, 1.3) : root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: !root.completed && (!!root.task.start || root.task.priority === "H")
        font.strikeout: root.completed
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.detailsRequested(root.task)
        }
      }

      RowLayout {
        visible: root.hasMetadata
        Layout.fillWidth: true
        spacing: Style.space(6)

        StatusPill {
          id: priorityPill
          visible: root.priorityLabel !== ""
          text: root.priorityLabel
          tint: root.priorityColor
          fontFamily: root.fontFamily
          Layout.alignment: Qt.AlignVCenter
        }

        StatusPill {
          id: duePill
          visible: root.completed ? !!root.task.end : !!root.task.due
          text: root.completed
            ? "󰄬 " + Model.taskDateTimeLabel(root.task.end)
            : (root.overdue ? "󰃰 " : "󰥔 ") + Model.taskDateTimeLabel(root.task.due)
          tint: root.overdue ? root.urgent : Qt.darker(root.foreground, 1.3)
          fontFamily: root.fontFamily
          Layout.alignment: Qt.AlignVCenter
        }

        Text {
          id: contextLabel
          visible: root.contextText !== ""
          Layout.fillWidth: true
          text: root.contextText
          color: Qt.darker(root.foreground, 1.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          Layout.alignment: Qt.AlignVCenter
        }
      }
    }

    BorderSurface {
      implicitWidth: actionRow.implicitWidth + Style.space(8)
      implicitHeight: actionRow.implicitHeight + Style.space(6)
      color: root.actionsHot
        ? Style.normalFillFor(root.foreground, Color.accent)
        : "transparent"
      borderSpec: root.actionsHot
        ? Border.controlSpec("normal", root.foreground, Color.accent)
        : Border.none()
      radius: Style.cornerRadius
      opacity: root.actionsHot ? 1 : 0.48
      Layout.alignment: Qt.AlignVCenter

      Row {
        id: actionRow
        anchors.centerIn: parent
        spacing: Style.space(2)

        PanelActionButton {
          id: detailsButton
          iconText: "󰅀"
          tooltipText: "View full task"
          foreground: root.foreground
          hoverColor: Color.accent
          fontFamily: root.fontFamily
          focusable: true
          onClicked: root.detailsRequested(root.task)
        }

        PanelActionButton {
          id: trackingButton
          visible: !root.completed
          width: visible ? implicitWidth : 0
          height: visible ? implicitHeight : 0
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
          visible: !root.completed
          width: visible ? implicitWidth : 0
          height: visible ? implicitHeight : 0
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
          visible: !root.completed
          width: visible ? implicitWidth : 0
          height: visible ? implicitHeight : 0
          iconText: "󰄬"
          tooltipText: "Complete task"
          foreground: root.foreground
          hoverColor: Color.accent
          fontFamily: root.fontFamily
          enabled: !root.busy
          focusable: true
          onClicked: root.completeRequested(String(root.task.uuid || ""))
        }

        PanelActionButton {
          id: restoreButton
          visible: root.completed
          width: visible ? implicitWidth : 0
          height: visible ? implicitHeight : 0
          iconText: "󰕌"
          tooltipText: "Restore task"
          foreground: root.foreground
          hoverColor: Color.accent
          fontFamily: root.fontFamily
          enabled: !root.busy
          focusable: true
          onClicked: root.restoreRequested(String(root.task.uuid || ""))
        }
      }

      Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 120 } }
    }
  }
}
