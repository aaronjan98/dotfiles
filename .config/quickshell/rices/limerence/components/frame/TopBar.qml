import QtQuick
import Quickshell
import Quickshell.Wayland

import "../containers"
import "../../config" as C

StyledWindow {
  name: "topbar"
  required property ShellScreen screen
  screen: screen

  exclusion: ExclusionMode.Auto
  layer: WlrLayer.Top

  anchors { top: true; left: true; right: true }
  implicitHeight: C.Appearance.topH
  exclusiveZone: C.Appearance.topH

  Rectangle {
    anchors.fill: parent
    color: C.Appearance.bg
    radius: 0
    antialiasing: true
  }
}

