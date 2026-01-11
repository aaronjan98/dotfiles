import QtQuick
import Quickshell
import Quickshell.Wayland

import "../containers"
import "../../config" as C

StyledWindow {
  id: root
  name: "cornerpatch"

  required property ShellScreen screen
  screen: screen

  // Put this ABOVE TopBar/LeftBar so it receives clicks.
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusionMode: ExclusionMode.Ignore

  anchors { top: true; left: true }
  implicitWidth: C.Appearance.leftW
  implicitHeight: C.Appearance.topH

  // Solid background so we definitely have an input region
  Rectangle {
    anchors.fill: parent
    color: C.Appearance.bg
    radius: 0
    antialiasing: true
  }

  Image {
    anchors.centerIn: parent
    source: "../../assets/nix-snowflake-colours.svg"
    width: parent.width - (C.Appearance.innerPad * 2)
    height: parent.height - (C.Appearance.innerPad * 2)
    fillMode: Image.PreserveAspectFit
    smooth: true
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.AllButtons
    cursorShape: Qt.PointingHandCursor
    onEntered: console.log("entered cornerpatch")
    onClicked: (mouse) => console.log("NIX clicked button=", mouse.button, "x=", mouse.x, "y=", mouse.y)
  }
}

