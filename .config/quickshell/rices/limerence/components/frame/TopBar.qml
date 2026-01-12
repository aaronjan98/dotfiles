import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C

PanelWindow {
    id: root
    required property ShellScreen screen
    screen: screen

    exclusionMode: ExclusionMode.Auto
    anchors.top: true
    anchors.left: true
    anchors.right: true

    // Leave space on the left for the corner patch + left bar lane.
    // This prevents the top bar from occupying the top-left square.
    margins.left: C.Appearance.leftW
    margins.top: 0
    margins.right: 0

    implicitHeight: C.Appearance.topH
    color: "transparent"

    // (later) top-bar content goes here.
}

