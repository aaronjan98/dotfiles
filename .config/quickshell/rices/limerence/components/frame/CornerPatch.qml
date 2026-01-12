import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C

PanelWindow {
    id: root
    required property ShellScreen screen
    screen: screen

    exclusionMode: ExclusionMode.Ignore
    anchors.top: true
    anchors.left: true

    implicitWidth: C.Appearance.leftW
    implicitHeight: C.Appearance.topH
    color: "transparent"

    Rectangle {
      id: bubble
      anchors.centerIn: parent
      width: C.Appearance.nixBubbleSize
      height: C.Appearance.nixBubbleSize
      radius: 6
      color: C.Appearance.bubbleBg
      border.width: 1
      border.color: C.Appearance.bubbleBorder
      antialiasing: true
    
      Image {
        anchors.fill: parent
        anchors.margins: C.Appearance.nixIconPad
        source: "../../assets/nix-snowflake-colours.svg"
        fillMode: Image.PreserveAspectFit
        smooth: true
      }
    }

    MouseArea {
        anchors.fill: bubble
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: console.log("Nix icon clicked")
    }
}

