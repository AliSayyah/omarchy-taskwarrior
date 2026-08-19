import QtQuick
import qs.Commons

Text {
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  color: Qt.darker(foreground, 1.4)
  font.family: fontFamily
  font.pixelSize: Style.font.caption
  font.bold: true
  font.letterSpacing: 0.7
}
