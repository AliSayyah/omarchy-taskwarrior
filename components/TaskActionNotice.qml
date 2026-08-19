import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  property var task: null
  property bool busy: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal restoreRequested(string uuid)
  signal dismissRequested()

  visible: !!task
  implicitHeight: noticeRow.implicitHeight + Style.space(12)
  color: Style.normalFillFor(Color.accent, Color.accent)
  borderSpec: Border.controlSpec("normal", Color.accent, Color.accent)
  radius: Style.cornerRadius

  onTaskChanged: {
    if (task) dismissTimer.restart()
    else dismissTimer.stop()
  }

  Timer {
    id: dismissTimer
    interval: 7000
    onTriggered: root.dismissRequested()
  }

  RowLayout {
    id: noticeRow
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(9)
    anchors.rightMargin: Style.space(6)
    spacing: Style.space(8)

    Text {
      Layout.fillWidth: true
      text: root.task ? "Completed · " + String(root.task.description || "Task") : ""
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
      elide: Text.ElideRight
    }

    Button {
      text: root.busy ? "Restoring…" : "Restore"
      iconText: "󰕌"
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      horizontalPadding: Style.space(8)
      verticalPadding: Style.space(4)
      bordered: true
      focusable: true
      enabled: !root.busy
      onClicked: root.restoreRequested(String(root.task ? root.task.uuid || "" : ""))
    }

    PanelActionButton {
      iconText: "󰅖"
      tooltipText: "Dismiss"
      foreground: root.foreground
      fontFamily: root.fontFamily
      focusable: true
      onClicked: root.dismissRequested()
    }
  }
}
