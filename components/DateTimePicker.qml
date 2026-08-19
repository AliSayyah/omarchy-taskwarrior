import "../Model.js" as Model
import QtQuick
import QtQuick.Controls.Basic as QQCB
import qs.Commons
import qs.Ui

Column {
  id: root

  property string value: ""
  property bool expanded: false
  property date selectedDate: new Date()
  property int viewYear: selectedDate.getFullYear()
  property int viewMonth: selectedDate.getMonth()
  property int hour: selectedDate.getHours()
  property int minute: selectedDate.getMinutes()
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  readonly property real calendarSpacing: Style.space(4)
  readonly property real dayWidth: (pickerColumn.width - calendarSpacing * 6) / 7

  signal changed(string value)
  signal escapeRequested()

  function roundedNow() {
    var now = new Date()
    now.setSeconds(0, 0)
    now.setMinutes(Math.ceil(now.getMinutes() / 5) * 5)
    return now
  }

  function loadValue() {
    var parsed = Model.parseLocalDateTime(value)
    var date = parsed || roundedNow()
    selectedDate = new Date(date.getTime())
    viewYear = date.getFullYear()
    viewMonth = date.getMonth()
    hour = date.getHours()
    minute = date.getMinutes()
  }

  function toggle() {
    if (!expanded) loadValue()
    expanded = !expanded
  }

  function close() {
    expanded = false
    loadValue()
  }

  function stepMonth(delta) {
    var target = new Date(viewYear, viewMonth + delta, 1)
    viewYear = target.getFullYear()
    viewMonth = target.getMonth()
  }

  function sameDay(left, right) {
    return left && right
      && left.getFullYear() === right.getFullYear()
      && left.getMonth() === right.getMonth()
      && left.getDate() === right.getDate()
  }

  function selectDate(date) {
    selectedDate = new Date(date.getFullYear(), date.getMonth(), date.getDate(), hour, minute)
  }

  function selectToday() {
    var today = roundedNow()
    selectedDate = today
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
    hour = today.getHours()
    minute = today.getMinutes()
  }

  function apply() {
    var date = new Date(
      selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate(),
      hour, minute, 0, 0)
    changed(Model.formatLocalDateTime(date))
    expanded = false
  }

  function clear() {
    changed("")
    expanded = false
  }

  spacing: Style.space(6)

  onValueChanged: if (!expanded) loadValue()
  Component.onCompleted: loadValue()
  Keys.onEscapePressed: {
    if (expanded) close()
    else escapeRequested()
  }

  Button {
    width: parent.width
    text: root.value ? root.value.replace("T", "  ") : "No due date"
    iconText: "󰃭"
    tooltipText: root.expanded ? "Close date and time picker" : "Choose date and time"
    foreground: root.foreground
    fontFamily: root.fontFamily
    leftAlign: true
    bordered: true
    selected: root.expanded
    focusable: true
    onClicked: root.toggle()
  }

  BorderSurface {
    visible: root.expanded
    width: parent.width
    implicitHeight: pickerColumn.implicitHeight + Style.space(20)
    color: Style.normalFillFor(root.foreground, Color.accent)
    borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
    radius: Style.cornerRadius

    Column {
      id: pickerColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(7)

      Item {
        width: parent.width
        implicitHeight: monthTitle.implicitHeight + Style.space(8)

        PanelActionButton {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          iconText: "󰅁"
          tooltipText: "Previous month"
          foreground: root.foreground
          fontFamily: root.fontFamily
          focusable: true
          onClicked: root.stepMonth(-1)
        }

        Text {
          id: monthTitle
          anchors.centerIn: parent
          text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }

        PanelActionButton {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          iconText: "󰅂"
          tooltipText: "Next month"
          foreground: root.foreground
          fontFamily: root.fontFamily
          focusable: true
          onClicked: root.stepMonth(1)
        }
      }

      QQCB.DayOfWeekRow {
        width: parent.width
        spacing: root.calendarSpacing
        locale: Qt.locale()
        delegate: Text {
          required property string shortName
          width: root.dayWidth
          height: Style.space(20)
          text: shortName
          color: Qt.darker(root.foreground, 1.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
      }

      QQCB.MonthGrid {
        id: monthGrid
        width: parent.width
        month: root.viewMonth
        year: root.viewYear
        spacing: root.calendarSpacing
        locale: Qt.locale()

        delegate: Button {
          required property var model
          width: root.dayWidth
          height: Style.space(30)
          text: model.day
          enabled: model.month === monthGrid.month
          selected: enabled && root.sameDay(model.date, root.selectedDate)
          foreground: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.caption
          horizontalPadding: 0
          verticalPadding: 0
          opacity: enabled ? 1 : 0.22
          focusable: enabled
          onClicked: root.selectDate(model.date)
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(12)

        NumberField {
          label: "Hour"
          value: root.hour
          from: 0
          to: 23
          fieldWidth: Style.space(72)
          foreground: root.foreground
          fontFamily: root.fontFamily
          onModified: function(value) { root.hour = value }
        }

        NumberField {
          label: "Minute"
          value: root.minute
          from: 0
          to: 59
          stepSize: 5
          fieldWidth: Style.space(72)
          foreground: root.foreground
          fontFamily: root.fontFamily
          onModified: function(value) { root.minute = value }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        Button {
          id: clearButton
          text: "Clear"
          foreground: root.foreground
          fontFamily: root.fontFamily
          bordered: true
          focusable: true
          onClicked: root.clear()
        }

        Button {
          id: todayButton
          text: "Today"
          foreground: root.foreground
          fontFamily: root.fontFamily
          bordered: true
          focusable: true
          onClicked: root.selectToday()
        }

        Item {
          width: parent.width - clearButton.width - todayButton.width - cancelButton.width - applyButton.width - parent.spacing * 4
          height: 1
        }

        Button {
          id: cancelButton
          text: "Cancel"
          foreground: root.foreground
          fontFamily: root.fontFamily
          bordered: true
          focusable: true
          onClicked: root.close()
        }

        Button {
          id: applyButton
          text: "Apply"
          foreground: root.foreground
          fontFamily: root.fontFamily
          selected: true
          bordered: true
          focusable: true
          onClicked: root.apply()
        }
      }
    }
  }
}
