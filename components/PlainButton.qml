import QtQuick
import qs.Commons
import qs.Ui

Button {
  id: root

  property string label: ""

  text: ""
  implicitWidth: plainLabel.implicitWidth + horizontalPadding * 2
    + _reservedBorderLeft + _reservedBorderRight
  implicitHeight: plainLabel.implicitHeight + verticalPadding * 2
    + _reservedBorderTop + _reservedBorderBottom

  Text {
    id: plainLabel
    anchors.centerIn: parent
    text: root.label
    textFormat: Text.PlainText
    color: root.selected ? Style.selectedStateColor(root.foreground, root.accent) : root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.bold: root.selected
  }
}
