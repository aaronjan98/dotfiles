import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C

PanelWindow {
    id: root
    required property ShellScreen screen
    screen: screen

    // Layershell / panel behavior
    exclusionMode: ExclusionMode.Auto
    anchors.left: true
    anchors.top: true
    anchors.bottom: true

    // IMPORTANT: PanelWindow uses `margins`, not anchors.topMargin
    // This makes the left bar start *below* the top bar, without overlapping.
    margins.top: C.Appearance.topH
    margins.left: 0
    margins.bottom: 0

    implicitWidth: C.Appearance.leftW
    color: "transparent"

    // (later) actual left-bar content goes here.
    // For now, leave it empty since you said: bars themselves are not colored.
}

