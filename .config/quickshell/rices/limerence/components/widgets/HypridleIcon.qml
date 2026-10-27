import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

// Standalone bar icon (not inside a pill) to toggle hypridle (screen sleep / auto dim / lock).
// Normal state (hypridle running): coffee-off glyph in standard topbar white/grey.
// Keep-awake state (hypridle stopped): full coffee cup glyph in warm caffeine amber.
Item {
  id: root
  implicitWidth: C.Appearance.topbarIconBoxW
  implicitHeight: C.Appearance.topbarIconBoxH

  readonly property bool keepAwake: Sv.HypridleCtl.keepAwake

  Text {
    id: glyph
    anchors.centerIn: parent
    text: root.keepAwake ? "󰅶" : "󰛊" // nf-md-coffee vs nf-md-coffee_off
    color: root.keepAwake
      ? (mouseArea.containsMouse ? Qt.rgba(1.0, 0.80, 0.45, 1.0) : Qt.rgba(0.95, 0.72, 0.38, 0.95))
      : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.65))
    font.family: C.Appearance.iconFont
    font.pixelSize: C.Appearance.topbarIconPx

    Behavior on color {
      ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Sv.HypridleCtl.toggle()
  }
}
