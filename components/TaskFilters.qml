import QtQuick
import qs.Commons
import qs.Ui

Row {
  id: root

  property var options: []
  property string value: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal selected(string value)

  spacing: Style.space(4)

  Repeater {
    model: root.options

    delegate: Button {
      required property var modelData

      text: modelData.label + (modelData.count === null ? "" : "  " + modelData.count)
      selected: modelData.value === root.value
      bordered: true
      focusable: true
      foreground: root.foreground
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      horizontalPadding: Style.space(10)
      verticalPadding: Style.space(5)
      opacity: modelData.count === null || modelData.value === "all" || modelData.count > 0 ? 1 : 0.42
      onClicked: root.selected(modelData.value)

      Behavior on opacity { NumberAnimation { duration: 120 } }
    }
  }
}
