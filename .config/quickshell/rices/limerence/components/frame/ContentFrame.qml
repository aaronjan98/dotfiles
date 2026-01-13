import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C

PanelWindow {
  id: win
  required property ShellScreen screen
  screen: screen

  // Visual-only overlay: never reserves space
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true

  // Click-through: empty input region
  mask: Region { }
  color: "transparent"

  // "workArea" = the intended Hyprland content region (the HOLE)
  // Everything OUTSIDE this rectangle gets tinted (the ring).
  Item {
    id: hole
    anchors.fill: parent

    // align to the same offsets your bars reserve
    anchors.leftMargin: C.Appearance.leftW
    anchors.topMargin: C.Appearance.topH

    // allow extra frame visible on right/bottom
    anchors.rightMargin: C.Appearance.framePadRight
    anchors.bottomMargin: C.Appearance.framePadBottom
  }

  //
  // RING: 4 strips around the hole (outside only)
  //

  // Top strip: above the hole
  Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: hole.top
    color: C.Appearance.frameBg
  }

  // Left strip: left of the hole
  Rectangle {
    anchors.top: hole.top
    anchors.bottom: hole.bottom
    anchors.left: parent.left
    anchors.right: hole.left
    color: C.Appearance.frameBg
  }

  // Right strip: right of the hole
  Rectangle {
    anchors.top: hole.top
    anchors.bottom: hole.bottom
    anchors.left: hole.right
    anchors.right: parent.right
    color: C.Appearance.frameBg
  }

  // Bottom strip: below the hole
  Rectangle {
    anchors.top: hole.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    color: C.Appearance.frameBg
  }

  //
  // INWARD GLOW / INNER BORDER: drawn inside the hole (so it points inward)
  //

  Item {
    id: inner
    x: hole.x
    y: hole.y
    width: hole.width
    height: hole.height

    // Outer-most inner glow
    Rectangle {
      anchors.fill: parent
      radius: C.Appearance.frameRadius
      color: "transparent"
      border.width: 1
      border.color: C.Appearance.glow1
      antialiasing: true
    }

    // Mid glow
    Rectangle {
      anchors.fill: parent
      anchors.margins: 2
      radius: Math.max(0, C.Appearance.frameRadius - 2)
      color: "transparent"
      border.width: 1
      border.color: C.Appearance.glow2
      antialiasing: true
    }

    // Inner glow
    Rectangle {
      anchors.fill: parent
      anchors.margins: 4
      radius: Math.max(0, C.Appearance.frameRadius - 4)
      color: "transparent"
      border.width: 1
      border.color: C.Appearance.glow3
      antialiasing: true
    }

    // Crisp inner ring
    Rectangle {
      anchors.fill: parent
      anchors.margins: C.Appearance.borderInset
      radius: Math.max(0, C.Appearance.frameRadius - C.Appearance.borderInset)
      color: "transparent"
      border.width: C.Appearance.border
      border.color: C.Appearance.borderCol
      antialiasing: true
    }
  }
}

