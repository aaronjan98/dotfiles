import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C

PanelWindow {
  id: win
  // screen set by caller — not re-declared here to avoid shadowing PanelWindow.screen
  property bool isExternal: false
  readonly property real contentScale: isExternal ? C.Appearance.externalCornerScale : 1

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  anchors.top: true
  anchors.left: true

  // THIS is what makes nixBubbleSize matter:
  implicitWidth: Math.round(C.Appearance.nixBubbleSize * contentScale)
  implicitHeight: isExternal ? C.Appearance.topHExternal : Math.round(C.Appearance.nixBubbleSize * contentScale)

  color: "transparent"

  Rectangle {
    id: bubble
    width: Math.round(C.Appearance.nixBubbleSize * win.contentScale)
    height: width
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: isExternal ? -Math.max(1, Math.round(C.Appearance.s(2) * C.Appearance.externalFrameScale)) : 0
    radius: Math.round(C.Appearance.bubbleRadius * win.contentScale)
    color: C.Appearance.bubbleBg
    antialiasing: true
    clip: true

    border.width: C.Appearance.bubbleBorderEnabled ? C.Appearance.bubbleBorderW : 0
    border.color: C.Appearance.bubbleBorderEnabled ? C.Appearance.bubbleBorderCol : "transparent"


    // Icon container so padding is consistent and alignment is easy
    Item {
      id: iconBox
      anchors.fill: parent
      anchors.margins: Math.round(C.Appearance.nixIconPad * win.contentScale)

      Image {
        id: nix
        anchors.centerIn: parent

        anchors.horizontalCenterOffset: 0
        anchors.verticalCenterOffset: 0

        source: "qs:@/qs/assets/icons/nix-snowflake/nix-snowflake-colours.svg"

        width: Math.min(parent.width, parent.height) * 0.95
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
