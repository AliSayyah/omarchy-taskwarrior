import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  property string text: ""
  property color tint: Color.foreground
  property string fontFamily: Style.font.family

  implicitWidth: label.implicitWidth + Style.space(10)
  implicitHeight: label.implicitHeight + Style.space(4)
  color: Style.normalFillFor(tint, Color.accent)
  borderSpec: Border.controlSpec("normal", tint, Color.accent)
  radius: Style.cornerRadius

  Text {
    id: label
    anchors.centerIn: parent
    text: root.text
    textFormat: Text.PlainText
    color: root.tint
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    font.bold: true
  }
}
