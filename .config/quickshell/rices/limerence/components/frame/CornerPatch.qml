import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C

PanelWindow {
  id: win
  // screen set by caller — not re-declared here to avoid shadowing PanelWindow.screen
  property bool isExternal: false
  readonly property real contentScale: isExternal ? C.Appearance.externalCornerScale : 1.12
  readonly property int bubbleExtent: isExternal ? C.Appearance.topHExternal : C.Appearance.topHFramework

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  anchors.top: true
  anchors.left: true

  // THIS is what makes nixBubbleSize matter:
  implicitWidth: Math.round(C.Appearance.nixBubbleSize * contentScale)
  implicitHeight: bubbleExtent

  color: "transparent"

  Rectangle {
    id: bubble
    width: Math.round(C.Appearance.nixBubbleSize * win.contentScale)
    height: width
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    // External: sit on the true vertical centre, matching the top-bar islands (their
    // old negative offset read ~6px high). Laptop keeps its small downward nudge.
    anchors.verticalCenterOffset: isExternal
      ? 0
      : Math.max(1, C.Appearance.s(1))
    radius: Math.round(C.Appearance.bubbleRadius * win.contentScale)
    // No chip behind the Nix snowflake: the logo is already colourful, so a bubble
    // just competes with it (and would now pop with the higher-contrast islands).
    // Let the logo float in the corner.
    color: "transparent"
    antialiasing: true
    clip: true

    border.width: 0
    border.color: "transparent"


    // Icon container so padding is consistent and alignment is easy
    Item {
      id: iconBox
      width: parent.width - Math.round(C.Appearance.nixIconPad * win.contentScale) * 2
      height: width
      anchors.centerIn: parent

      Image {
        id: nix
        anchors.centerIn: parent

        anchors.horizontalCenterOffset: 0
        anchors.verticalCenterOffset: 0

        source: "qs:@/qs/assets/icons/nix-snowflake/nix-snowflake-colours.svg"

      width: Math.min(parent.width, parent.height) * 0.92
        height: width

        fillMode: Image.PreserveAspectFit
        smooth: true
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: console.log("Nix bubble clicked")
    }
  }
}
