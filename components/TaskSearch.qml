import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root

  property string query: ""
  property string filterKind: ""
  property string filterValue: ""
  property var projects: []
  property var tags: []
  property bool completed: false
  property bool expanded: false
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  readonly property bool hasFilter: filterKind !== ""

  signal searchChanged(string text)
  signal filterChanged(string kind, string value)
  signal closeRequested()

  function collapse() { expanded = false }
  function choose(kind, value) { filterChanged(String(kind || ""), String(value || "")) }

  spacing: Style.space(7)

  Item {
    width: parent.width
    implicitHeight: searchField.implicitHeight

    TextField {
      id: searchField
      anchors.fill: parent
      text: root.query
      placeholderText: "Search tasks, projects, tags, or notes"
      foreground: root.foreground
      font.family: root.fontFamily
      rightPadding: filterButton.width + (clearButton.visible ? clearButton.width : 0) + Style.space(14)
      onTextChanged: if (text !== root.query) root.searchChanged(text)
      Keys.onEscapePressed: {
        if (root.expanded) root.collapse()
        else root.closeRequested()
      }
    }

    PanelActionButton {
      id: filterButton
      anchors.right: parent.right
      anchors.rightMargin: Style.space(5)
      anchors.verticalCenter: parent.verticalCenter
      size: Math.max(Style.space(24), searchField.height - Style.space(10))
      iconText: "󰈲"
      tooltipText: root.expanded ? "Hide filters" : "Filter tasks"
      foreground: root.foreground
      hoverColor: Color.accent
      fontFamily: root.fontFamily
      bordered: root.hasFilter || root.expanded
      focusable: true
      onClicked: root.expanded = !root.expanded
    }

    PanelActionButton {
      id: clearButton
      visible: root.query !== ""
      anchors.right: filterButton.left
      anchors.rightMargin: Style.space(2)
      anchors.verticalCenter: parent.verticalCenter
      size: filterButton.size
      iconText: "󰅖"
      tooltipText: "Clear search"
      foreground: root.foreground
      fontFamily: root.fontFamily
      focusable: true
      onClicked: root.searchChanged("")
    }
  }

  BorderSurface {
    visible: root.expanded
    width: parent.width
    implicitHeight: filterColumn.implicitHeight + Style.space(18)
    color: Style.normalFillFor(root.foreground, Color.accent)
    borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
    radius: Style.cornerRadius

    Column {
      id: filterColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(9)
      anchors.rightMargin: Style.space(9)
      spacing: Style.space(7)

      PanelSectionHeader {
        text: "FILTER"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Flow {
        width: parent.width
        height: childrenRect.height
        spacing: Style.space(5)

        Button {
          text: "Any"
          selected: !root.hasFilter
          bordered: true
          focusable: true
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.caption
          horizontalPadding: Style.space(8)
          verticalPadding: Style.space(4)
          onClicked: root.choose("", "")
        }

        Repeater {
          model: root.completed ? [] : [
            { kind: "active", label: "Active" },
            { kind: "blocked", label: "Blocked" },
            { kind: "waiting", label: "Waiting" }
          ]

          delegate: Button {
            required property var modelData
            text: modelData.label
            selected: root.filterKind === modelData.kind
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(4)
            onClicked: root.choose(modelData.kind, "")
          }
        }
      }

      PanelSectionHeader {
        visible: root.projects.length > 0
        text: "PROJECTS"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Flow {
        visible: root.projects.length > 0
        width: parent.width
        height: visible ? childrenRect.height : 0
        spacing: Style.space(5)

        Repeater {
          model: root.projects.slice(0, 8)
          delegate: PlainButton {
            required property string modelData
            label: "󰏗 " + modelData
            selected: root.filterKind === "project" && root.filterValue === modelData
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(4)
            onClicked: root.choose("project", modelData)
          }
        }
      }

      PanelSectionHeader {
        visible: root.tags.length > 0
        text: "TAGS"
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      Flow {
        visible: root.tags.length > 0
        width: parent.width
        height: visible ? childrenRect.height : 0
        spacing: Style.space(5)

        Repeater {
          model: root.tags.slice(0, 8)
          delegate: PlainButton {
            required property string modelData
            label: "+" + modelData
            selected: root.filterKind === "tag" && root.filterValue === modelData
            bordered: true
            focusable: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(4)
            onClicked: root.choose("tag", modelData)
          }
        }
      }
    }
  }
}
