import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  property string text: ""
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family

  visible: text !== ""
  implicitHeight: label.implicitHeight + Style.space(12)
  color: Style.normalFillFor(urgent, Color.accent)
  borderSpec: Border.controlSpec("normal", urgent, Color.accent)
  radius: Style.cornerRadius

  Text {
    id: label
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(8)
    anchors.rightMargin: Style.space(8)
    text: root.text
    color: root.urgent
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
