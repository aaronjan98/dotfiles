import QtQuick
import Quickshell

import "../containers"
import "../effects"
import "../../config" as C

StyledWindow {
  name: "cornercap"
  required property ShellScreen screen
  screen: screen

  anchors { top: true; left: true }
  implicitWidth: C.Appearance.leftW
  implicitHeight: C.Appearance.topH

  // do NOT reserve extra space
  exclusiveZone: 0

  Rectangle {
    anchors.fill: parent
    color: C.Appearance.bg
    radius: C.Appearance.rLarge
    antialiasing: true
  }

  InnerBorder {
    thickness: C.Appearance.border
    innerRadius: C.Appearance.rNormal
    color: C.Appearance.borderCol
  }

  // Logo (SVG) — if SVG doesn’t render, we’ll convert to PNG next.
  Image {
    anchors.centerIn: parent
    source: "../../assets/nix-snowflake-colours.svg"
    width: 24
    height: 24
    fillMode: Image.PreserveAspectFit
    smooth: true
  }
}

