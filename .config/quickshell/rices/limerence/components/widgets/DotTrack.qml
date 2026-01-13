import QtQuick
import "../widgets" as W

Item {
  id: root

  // public API
  property int count: 4
  property int activeIndex: 0          // 0-based
  property var occupiedFn: function(i){ return false }  // (i)->bool
  property string axis: "h"            // "h" or "v"
  property int dotSize: 7
  property real pillFactor: 2.1
  property int gap: 4
  property int animMs: 140

  signal clicked(int index)

  // compute target extent for each index
  function extentFor(i) {
    return (i === activeIndex) ? Math.round(dotSize * pillFactor) : dotSize
  }

  // let parent bubble size to us
  implicitWidth: axis === "h"
    ? (sumExtents() + gap * Math.max(0, count - 1))
    : dotSize

  implicitHeight: axis === "v"
    ? (sumExtents() + gap * Math.max(0, count - 1))
    : dotSize

  function sumExtents() {
    var s = 0
    for (var i = 0; i < count; i++) s += extentFor(i)
    return s
  }

  Repeater {
    model: root.count

    delegate: Item {
      id: cell
      readonly property int i: modelData
      readonly property int extent: root.extentFor(i)
      readonly property bool occ: root.occupiedFn(i)

      // Size of the "shape" (dot or pill) along the axis
      width:  (root.axis === "h") ? extent : root.dotSize
      height: (root.axis === "v") ? extent : root.dotSize

      // Position computed from previous siblings so edge gaps stay constant.
      x: {
        if (root.axis !== "h") return 0
        var px = 0
        for (var k = 0; k < i; k++) px += root.extentFor(k) + root.gap
        return px
      }
      y: {
        if (root.axis !== "v") return 0
        var py = 0
        for (var k = 0; k < i; k++) py += root.extentFor(k) + root.gap
        return py
      }

      Behavior on x { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
      Behavior on y { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
      Behavior on width  { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
      Behavior on height { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }

      // Draw the dot/pill itself (filled)
      Rectangle {
        anchors.fill: parent
        radius: root.dotSize / 2
        antialiasing: true
        color: "white"
        opacity: (i === root.activeIndex) ? 0.95 : (occ ? 0.60 : 0.35)
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked(i)
      }
    }
  }
}

