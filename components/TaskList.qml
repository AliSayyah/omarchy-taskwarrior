import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Column {
  id: root

  property var tasks: []
  property int totalCount: 0
  property string filter: "ready"
  property string errorText: ""
  property bool busy: false
  property bool loading: false
  property bool hasMore: false
  property bool remoteHasMore: false
  property bool loadScheduled: false
  property color foreground: Color.foreground
  property color urgent: Color.urgent
  property string fontFamily: Style.font.family

  signal loadMoreRequested()
  signal trackingRequested(var task)
  signal editRequested(var task)
  signal completeRequested(string uuid)

  function resetScroll() { taskFlick.contentY = 0 }
  function requestMore() {
    if (!hasMore || loadScheduled) return
    loadScheduled = true
    loadMoreRequested()
    Qt.callLater(function() { loadScheduled = false })
  }
  function scrollBy(delta) {
    var maximum = Math.max(0, taskFlick.contentHeight - taskFlick.height)
    taskFlick.contentY = Math.max(0, Math.min(maximum, taskFlick.contentY + delta))
    if (taskFlick.contentY >= maximum - 1) requestMore()
  }
  function emptyTitle() {
    if (filter === "overdue") return "Nothing overdue"
    if (filter === "today") return "Nothing due today"
    if (filter === "ready") return "Nothing ready"
    if (filter === "done") return "No completed tasks"
    return "No pending tasks"
  }
  function emptyDetail() {
    if (filter === "all") return "Add one above when something comes up."
    if (filter === "done") return "Finished tasks will appear here."
    return "You're clear for now."
  }

  spacing: Style.space(12)

  PanelSeparator { foreground: root.foreground }

  Item {
    width: parent.width
    implicitHeight: Math.max(listHeading.implicitHeight, listCount.implicitHeight)

    PanelSectionHeader {
      id: listHeading
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: root.filter.toUpperCase()
      foreground: root.foreground
      fontFamily: root.fontFamily
    }

    Text {
      id: listCount
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: root.totalCount + (root.totalCount === 1 ? " task" : " tasks")
      color: Qt.darker(root.foreground, 1.5)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  Item {
    visible: root.tasks.length === 0 && root.errorText === "" && !root.loading
    width: parent.width
    implicitHeight: emptyState.implicitHeight + Style.space(24)

    Column {
      id: emptyState
      anchors.centerIn: parent
      spacing: Style.space(5)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.filter === "overdue" || root.filter === "done" ? "󰄬" : "󰔚"
        color: Qt.darker(root.foreground, 1.35)
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.emptyTitle()
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.emptyDetail()
        color: Qt.darker(root.foreground, 1.55)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }

  Item {
    visible: root.loading && root.tasks.length === 0
    width: parent.width
    implicitHeight: loadingState.implicitHeight + Style.space(24)

    Column {
      id: loadingState
      anchors.centerIn: parent
      spacing: Style.space(6)

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "󰑐"
        color: Color.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        RotationAnimation on rotation {
          from: 0; to: 360; duration: 900; loops: Animation.Infinite; running: loadingState.visible
        }
      }
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Loading completed tasks…"
        color: Qt.darker(root.foreground, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }

  Item {
    id: taskListFrame
    visible: root.tasks.length > 0
    width: parent.width
    height: Math.min(taskColumn.implicitHeight, Style.space(360))

    Flickable {
      id: taskFlick
      anchors.fill: parent
      contentWidth: width
      contentHeight: taskColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      onMovementEnded: if (atYEnd) root.requestMore()

      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      WheelHandler {
        onWheel: function(event) {
          if (event.angleDelta.y === 0) return
          root.scrollBy(-event.angleDelta.y / 120 * Style.space(52))
          event.accepted = true
        }
      }

      Column {
        id: taskColumn
        width: taskFlick.width
        spacing: Style.space(7)

        Repeater {
          model: root.tasks
          delegate: TaskCard {
            required property var modelData
            width: taskColumn.width
            task: modelData
            busy: root.busy
            foreground: root.foreground
            urgent: root.urgent
            fontFamily: root.fontFamily
            onTrackingRequested: function(task) { root.trackingRequested(task) }
            onEditRequested: function(task) { root.editRequested(task) }
            onCompleteRequested: function(uuid) { root.completeRequested(uuid) }
          }
        }

        Text {
          visible: root.loading && root.tasks.length > 0
          width: parent.width
          text: "Loading more…"
          color: Qt.darker(root.foreground, 1.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

  }

  Text {
    visible: root.hasMore
    width: parent.width
    text: "Showing " + root.tasks.length + " of " + root.totalCount + (root.remoteHasMore ? "+" : "")
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  BorderSurface {
    visible: root.errorText !== ""
    width: parent.width
    implicitHeight: errorLabel.implicitHeight + Style.space(12)
    color: Style.normalFillFor(root.urgent, Color.accent)
    borderSpec: Border.controlSpec("normal", root.urgent, Color.accent)
    radius: Style.cornerRadius

    Text {
      id: errorLabel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(8)
      anchors.rightMargin: Style.space(8)
      text: root.errorText
      color: root.urgent
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }
}
