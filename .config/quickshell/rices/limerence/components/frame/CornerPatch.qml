import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C

PanelWindow {
  id: win
  required property ShellScreen screen
  screen: screen

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  anchors.top: true
  anchors.left: true

  // THIS is what makes nixBubbleSize matter:
  implicitWidth: C.Appearance.nixBubbleSize
  implicitHeight: C.Appearance.nixBubbleSize

  color: "transparent"

  Rectangle {
    id: bubble
    anchors.fill: parent
    radius: C.Appearance.bubbleRadius
    color: C.Appearance.bubbleBg
    antialiasing: true
    clip: true

    border.width: C.Appearance.bubbleBorderEnabled ? C.Appearance.bubbleBorderW : 0
    border.color: C.Appearance.bubbleBorderEnabled ? C.Appearance.bubbleBorderCol : "transparent"


    // Icon container so padding is consistent and alignment is easy
    Item {
      id: iconBox
      anchors.fill: parent
      anchors.margins: C.Appearance.nixIconPad

      Image {
        id: nix
        anchors.centerIn: parent

        anchors.horizontalCenterOffset: 0
        anchors.verticalCenterOffset: 0

        source: "qs:@/qs/assets/nix-snowflake-colours.svg"

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


