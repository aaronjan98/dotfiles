import QtQuick
import "../../config" as C

Item {
  id: root
  property bool active: false
  property bool occupied: false

  // Default now scaled via Appearance
  property int dotSize: C.Appearance.dotSize

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

    // Time should not scale; use Appearance token for consistency
    Behavior on opacity {
      NumberAnimation { duration: C.Appearance.animMsFast; easing.type: Easing.OutCubic }
    }
  }
}

