import QtQuick
import Quickshell
import Quickshell.Wayland

import "../containers"
import "../../config" as C

StyledWindow {
  name: "leftbar"
  required property ShellScreen screen
  screen: screen

  exclusion: ExclusionMode.Auto
  layer: WlrLayer.Top

  anchors { top: true; left: true; bottom: true }
  implicitWidth: C.Appearance.leftW
  exclusiveZone: C.Appearance.leftW

  // draw only below the top bar
  Rectangle {
    anchors.fill: parent
    anchors.topMargin: C.Appearance.topH
    color: C.Appearance.bg
    radius: 0
    antialiasing: true
  }
}

