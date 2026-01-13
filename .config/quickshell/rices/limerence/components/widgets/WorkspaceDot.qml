import QtQuick

Item {
  id: root
  property bool active: false
  property bool occupied: false
  property int dotSize: 7

  width: dotSize
  height: dotSize

  // For the hybrid: when active, we dim the dot a bit so the pill reads as the "active" mark.
  // If you want the dot to disappear entirely under the pill, set activeOpacity to 0.0.
  property real activeOpacity: 0.15

  Rectangle {
    anchors.fill: parent
    radius: root.dotSize / 2
    antialiasing: true
    color: "white"
    opacity: root.active
      ? root.activeOpacity
      : (root.occupied ? 0.60 : 0.35)

    Behavior on opacity {
      NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
    }
  }
}

