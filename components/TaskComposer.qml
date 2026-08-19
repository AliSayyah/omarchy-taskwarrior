import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool busy: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal submitRequested(string description)
  signal closeRequested()

  function focusInput() { input.forceActiveFocus() }
  function clear() { input.clear() }
  function submit() {
    var description = input.text.trim()
    if (description) submitRequested(description)
  }

  implicitHeight: input.implicitHeight

  TextField {
    id: input
    anchors.fill: parent
    rightPadding: addButton.width + Style.space(14)
    placeholderText: "What needs doing?"
    foreground: root.foreground
    font.family: root.fontFamily
    enabled: !root.busy
    onAccepted: root.submit()
    Keys.onEscapePressed: root.closeRequested()
  }

  PanelActionButton {
    id: addButton
    anchors.right: parent.right
    anchors.rightMargin: Style.space(5)
    anchors.verticalCenter: parent.verticalCenter
    size: Math.max(Style.space(24), input.height - Style.space(10))
    iconText: "󰐕"
    tooltipText: "Add task"
    foreground: root.foreground
    hoverColor: Color.accent
    fontFamily: root.fontFamily
    enabled: !root.busy && input.text.trim() !== ""
    focusable: true
    opacity: enabled ? 1 : 0.32
    onClicked: root.submit()

    Behavior on opacity { NumberAnimation { duration: 120 } }
  }
}
