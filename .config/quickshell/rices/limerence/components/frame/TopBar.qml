import QtQuick
import Quickshell

import "../containers"
import "../effects"
import "../../config" as C

StyledWindow {
  name: "topbar"
  required property ShellScreen screen
  screen: screen

  anchors { top: true; left: true; right: true }
  implicitHeight: C.Appearance.topH
  exclusiveZone: C.Appearance.topH

  // IMPORTANT: do not overlap corner square
  margins { left: C.Appearance.leftW }

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
}

