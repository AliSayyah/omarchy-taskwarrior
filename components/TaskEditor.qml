import "../Model.js" as Model
import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root

  property bool active: false
  property bool busy: false
  property var task: null
  property string description: ""
  property string project: ""
  property string priority: ""
  property string due: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  signal saveRequested(var task, var draft)
  signal cancelRequested()

  function begin(item) {
    task = item
    description = String(item.description || "")
    project = String(item.project || "")
    priority = String(item.priority || "")
    due = Model.taskDateTime(item.due)
    duePicker.close()
    active = true
    Qt.callLater(function() {
      descriptionField.forceActiveFocus()
      descriptionField.selectAll()
    })
  }

  function end() {
    duePicker.close()
    active = false
    task = null
  }

  function submit() {
    if (!task || !description.trim() || busy) return
    saveRequested(task, {
      description: description,
      project: project,
      priority: priority,
      due: due
    })
  }

  visible: active || opacity > 0
  opacity: active ? 1 : 0
  spacing: Style.space(8)

  Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

  PanelSectionHeader {
    text: "EDIT TASK"
    foreground: root.foreground
    fontFamily: root.fontFamily
  }

  FieldLabel { text: "DESCRIPTION"; foreground: root.foreground; fontFamily: root.fontFamily }

  TextField {
    id: descriptionField
    width: parent.width
    text: root.description
    placeholderText: "Description"
    foreground: root.foreground
    font.family: root.fontFamily
    enabled: !root.busy
    onTextChanged: root.description = text
    onAccepted: root.submit()
    Keys.onEscapePressed: root.cancelRequested()
  }

  FieldLabel { text: "PROJECT"; foreground: root.foreground; fontFamily: root.fontFamily }

  TextField {
    width: parent.width
    text: root.project
    placeholderText: "Optional"
    foreground: root.foreground
    font.family: root.fontFamily
    enabled: !root.busy
    onTextChanged: root.project = text
    onAccepted: root.submit()
    Keys.onEscapePressed: root.cancelRequested()
  }

  FieldLabel { text: "DUE DATE & TIME"; foreground: root.foreground; fontFamily: root.fontFamily }

  DateTimePicker {
    id: duePicker
    width: parent.width
    value: root.due
    foreground: root.foreground
    fontFamily: root.fontFamily
    onChanged: function(value) { root.due = value }
    onEscapeRequested: root.cancelRequested()
  }

  FieldLabel { text: "PRIORITY"; foreground: root.foreground; fontFamily: root.fontFamily }

  ButtonGroup {
    options: [
      { value: "", label: "None" },
      { value: "L", label: "Low" },
      { value: "M", label: "Medium" },
      { value: "H", label: "High" }
    ]
    value: root.priority
    foreground: root.foreground
    fontFamily: root.fontFamily
    onChanged: function(value) { root.priority = value }
    Keys.onEscapePressed: root.cancelRequested()
  }

  Row {
    width: parent.width
    spacing: Style.space(8)

    Item { width: parent.width - cancelButton.width - saveButton.width - parent.spacing * 2; height: 1 }

    Button {
      id: cancelButton
      text: "Cancel"
      foreground: root.foreground
      fontFamily: root.fontFamily
      focusable: true
      bordered: true
      enabled: !root.busy
      onClicked: root.cancelRequested()
    }

    Button {
      id: saveButton
      text: root.busy ? "Saving…" : "Save"
      foreground: root.foreground
      fontFamily: root.fontFamily
      focusable: true
      selected: true
      bordered: true
      enabled: !root.busy && root.description.trim() !== ""
      onClicked: root.submit()
    }
  }
}
