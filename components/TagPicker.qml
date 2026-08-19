import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root

  property var value: []
  property var suggestions: []
  property bool busy: false
  property string errorText: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  readonly property var visibleSuggestions: suggestions.filter(function(tag) {
    return value.indexOf(String(tag)) < 0
      && (input.text === "" || String(tag).toLowerCase().indexOf(input.text.toLowerCase()) >= 0)
  }).slice(0, 8)

  signal changed(var tags)
  signal escapeRequested()

  function clear() {
    input.clear()
    errorText = ""
  }

  function add(raw) {
    var tag = String(raw || "").trim().replace(/^\+/, "")
    if (!tag) return value.slice()
    if (/\s/.test(tag)) {
      errorText = "Tags cannot contain spaces"
      return null
    }
    var next = value.slice()
    if (next.indexOf(tag) < 0) next.push(tag)
    input.clear()
    errorText = ""
    changed(next)
    return next
  }

  function remove(tag) {
    changed(value.filter(function(item) { return item !== tag }))
  }

  function commit() {
    return input.text.trim() === "" ? value.slice() : add(input.text)
  }

  spacing: Style.space(7)

  FieldLabel { text: "TAGS"; foreground: root.foreground; fontFamily: root.fontFamily }

  Item {
    width: parent.width
    implicitHeight: input.implicitHeight

    TextField {
      id: input
      anchors.fill: parent
      rightPadding: addButton.width + Style.space(10)
      placeholderText: "Add a tag"
      foreground: root.foreground
      font.family: root.fontFamily
      enabled: !root.busy
      onAccepted: root.add(text)
      onTextChanged: root.errorText = ""
      Keys.onEscapePressed: root.escapeRequested()
    }

    PanelActionButton {
      id: addButton
      anchors.right: parent.right
      anchors.rightMargin: Style.space(5)
      anchors.verticalCenter: parent.verticalCenter
      size: Math.max(Style.space(24), input.height - Style.space(10))
      iconText: "󰐕"
      tooltipText: "Add tag"
      foreground: root.foreground
      hoverColor: Color.accent
      fontFamily: root.fontFamily
      enabled: input.text.trim() !== ""
      focusable: true
      onClicked: root.add(input.text)
    }
  }

  Text {
    visible: root.errorText !== ""
    width: parent.width
    text: root.errorText
    color: Color.urgent
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  Flow {
    visible: root.value.length > 0
    width: parent.width
    height: visible ? childrenRect.height : 0
    spacing: Style.space(5)

    Repeater {
      model: root.value
      delegate: PlainButton {
        required property string modelData
        label: "+" + modelData + "  ×"
        tooltipText: "Remove tag"
        selected: true
        bordered: true
        focusable: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        horizontalPadding: Style.space(8)
        verticalPadding: Style.space(4)
        onClicked: root.remove(modelData)
      }
    }
  }

  Flow {
    visible: root.visibleSuggestions.length > 0
    width: parent.width
    height: visible ? childrenRect.height : 0
    spacing: Style.space(5)

    Repeater {
      model: root.visibleSuggestions
      delegate: PlainButton {
        required property string modelData
        label: "+" + modelData
        bordered: true
        focusable: true
        foreground: root.foreground
        fontFamily: root.fontFamily
        fontSize: Style.font.caption
        horizontalPadding: Style.space(8)
        verticalPadding: Style.space(4)
        onClicked: root.add(modelData)
      }
    }
  }
}
