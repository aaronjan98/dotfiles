import QtQuick
import Quickshell

import "../containers"
import "../effects"
import "../../config" as C

StyledWindow {
  name: "leftbar"
  required property ShellScreen screen
  screen: screen

  anchors { top: true; left: true; bottom: true }
  implicitWidth: C.Appearance.leftW
  exclusiveZone: C.Appearance.leftW

  // IMPORTANT: do not overlap corner square
  margins { top: C.Appearance.topH }

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

