import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root

  property bool busy: false
  property bool expanded: false
  property string project: ""
  property string priority: ""
  property string due: ""
  property var tags: []
  property var projectSuggestions: []
  property var tagSuggestions: []
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  readonly property var visibleProjects: projectSuggestions.filter(function(value) {
    return project === "" || String(value).toLowerCase().indexOf(project.toLowerCase()) >= 0
  }).slice(0, 6)

  signal submitRequested(var draft)
  signal closeRequested()

  function focusInput() { input.forceActiveFocus() }

  function collapse() {
    expanded = false
    duePicker.close()
    tagPicker.clear()
  }

  function clear() {
    input.clear()
    project = ""
    priority = ""
    due = ""
    tags = []
    collapse()
  }

  function submit() {
    var description = input.text.trim()
    var selectedTags = tagPicker.commit()
    if (!description || busy || selectedTags === null) return
    tags = selectedTags
    submitRequested({
      description: description,
      project: project,
      priority: priority,
      due: due,
      tags: selectedTags
    })
  }

  spacing: Style.space(7)

  Item {
    width: parent.width
    implicitHeight: input.implicitHeight

    TextField {
      id: input
      anchors.fill: parent
      rightPadding: addButton.width + moreButton.width + Style.space(16)
      placeholderText: "What needs doing?"
      foreground: root.foreground
      font.family: root.fontFamily
      enabled: !root.busy
      onAccepted: root.submit()
      Keys.onEscapePressed: {
        if (root.expanded) root.collapse()
        else root.closeRequested()
      }
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

    PanelActionButton {
      id: moreButton
      anchors.right: addButton.left
      anchors.rightMargin: Style.space(2)
      anchors.verticalCenter: parent.verticalCenter
      size: addButton.size
      iconText: root.expanded ? "󰅃" : "󰅀"
      tooltipText: root.expanded ? "Hide task details" : "Add project, tags, priority, and due date"
      foreground: root.foreground
      hoverColor: Color.accent
      fontFamily: root.fontFamily
      bordered: root.expanded
      focusable: true
      onClicked: root.expanded ? root.collapse() : root.expanded = true
    }
  }

  BorderSurface {
    visible: root.expanded
    width: parent.width
    implicitHeight: metadataColumn.implicitHeight + Style.space(20)
    color: Style.normalFillFor(root.foreground, Color.accent)
    borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
    radius: Style.cornerRadius

    Column {
      id: metadataColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(7)

      FieldLabel { text: "PROJECT"; foreground: root.foreground; fontFamily: root.fontFamily }

      TextField {
        id: projectField
        width: parent.width
        text: root.project
        placeholderText: "Optional project"
        foreground: root.foreground
        font.family: root.fontFamily
        enabled: !root.busy
        onTextChanged: root.project = text
        Keys.onEscapePressed: root.collapse()
      }

      Flow {
        visible: root.visibleProjects.length > 0
        width: parent.width
        height: visible ? childrenRect.height : 0
        spacing: Style.space(5)

        Repeater {
          model: root.visibleProjects
          delegate: PlainButton {
            required property string modelData
            label: "󰏗 " + modelData
            selected: root.project === modelData
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(4)
            onClicked: root.project = modelData
          }
        }
      }

      TagPicker {
        id: tagPicker
        width: parent.width
        value: root.tags
        suggestions: root.tagSuggestions
        busy: root.busy
        foreground: root.foreground
        fontFamily: root.fontFamily
        onChanged: function(tags) { root.tags = tags }
        onEscapeRequested: root.collapse()
      }

      FieldLabel { text: "DUE DATE & TIME"; foreground: root.foreground; fontFamily: root.fontFamily }

      DateTimePicker {
        id: duePicker
        width: parent.width
        value: root.due
        enabled: !root.busy
        foreground: root.foreground
        fontFamily: root.fontFamily
        onChanged: function(value) { root.due = value }
        onEscapeRequested: root.collapse()
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
        enabled: !root.busy
        onChanged: function(value) { root.priority = value }
        Keys.onEscapePressed: root.collapse()
      }
    }
  }
}
