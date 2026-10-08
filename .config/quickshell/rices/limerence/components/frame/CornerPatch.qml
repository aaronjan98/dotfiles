import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

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
    // Nudge right on external so the left gap matches the top padding.
    anchors.horizontalCenterOffset: isExternal
      ? Math.round(C.Appearance.s(2) * C.Appearance.externalFrameScale)
      : 0
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
    // No chip/border here, so nothing needs clipping — and clipping was cutting the
    // snowflake's right arm against the bubble edge. Leave it off so the logo shows whole.
    clip: false

    border.width: 0
    border.color: "transparent"


    // Icon container so padding is consistent and alignment is easy
    Item {
      id: iconBox
      width: parent.width - Math.round(C.Appearance.nixIconPad * win.contentScale) * 2
      height: width
      anchors.centerIn: parent

      // Logo + its faked outline grouped together so the hover-spin rotates both.
      Item {
        id: nixGroup
        anchors.centerIn: parent
        // Larger glyph on the external bar only; the laptop keeps its original 0.92.
        width: Math.min(iconBox.width, iconBox.height) * (win.isExternal ? 1.0 : 0.92)
        height: width
        transformOrigin: Item.Center

        // Swap the logo with the scheme: rainbow in light mode, colours in dark.
        readonly property string logoSource: C.Appearance.isDark
          ? "qs:@/qs/assets/icons/nix-snowflake/nix-snowflake-colours.svg"
          : "qs:@/qs/assets/icons/nix-snowflake/nix-snowflake-rainbow.svg"
        // Outline thickness (px) and the 8 directions the black copies are stamped in.
        readonly property real outlineW: 1
        readonly property var outlineDirs: [[-1,-1],[0,-1],[1,-1],[-1,0],[1,0],[-1,1],[0,1],[1,1]]

        // Light mode only: fake a thin dark outline by stamping black copies of the
        // logo offset 1px in 8 directions behind the colour version (the same idea as
        // Text.Outline on the battery). Crisp, so it never spreads past the corner
        // window the way the soft shadow did.
        Repeater {
          model: C.Appearance.isDark ? [] : nixGroup.outlineDirs
          Image {
            source: nixGroup.logoSource
            width: nixGroup.width
            height: nixGroup.height
            x: modelData[0] * nixGroup.outlineW
            y: modelData[1] * nixGroup.outlineW
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.85
            layer.enabled: true
            layer.effect: MultiEffect {
              colorization: 1.0
              colorizationColor: Qt.rgba(0, 0, 0, 1)
            }
          }
        }

        Image {
          id: nix
          anchors.fill: parent
          source: nixGroup.logoSource
          fillMode: Image.PreserveAspectFit
          smooth: true
        }
      }
    }

    // Slow clockwise spin while hovered. Uses a NumberAnimation (updates rotation on
    // the main thread) so stopping freezes the logo at its current angle; each hover
    // starts from that frozen angle, so it resumes in place instead of snapping back.
    // from→to spans exactly 360°, so the infinite loop wraps seamlessly.
    NumberAnimation {
      id: nixSpin
      target: nixGroup
      property: "rotation"
      duration: 5000
      loops: Animation.Infinite
      running: false
    }

    MouseArea {
      id: hoverArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: {
        nixSpin.from = nixGroup.rotation
        nixSpin.to = nixGroup.rotation + 360
        nixSpin.restart()
      }
      onExited: nixSpin.stop()
      onClicked: console.log("Nix bubble clicked")
    }
  }
}
