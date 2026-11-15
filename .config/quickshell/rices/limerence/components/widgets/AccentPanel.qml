import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C
import "../services" 1.0 as Sv

// Display-only feedback panel for the AltGr+vowel accent flow (project-
// memory/kanata-island.md, Phase 2, accent-type/accent-cycle/accent-commit).
// Shows the variant row for whatever letter was just typed, with the
// current pick highlighted, next to the left-bar island.
//
// THE FOCUS CONSTRAINT (read before touching this file): this panel must
// NEVER take keyboard focus. wtype injects through the virtual-keyboard
// protocol, which delivers to whatever surface currently holds keyboard
// focus -- if this panel grabbed it to read arrow keys itself, every wtype
// call from accent-cycle would land HERE instead of the user's actual app,
// and the whole feature would silently do nothing. The arrow keys are
// captured by a Hyprland submap instead (conf.d/20-binds.conf), which
// intercepts keys globally without moving surface focus. This is the
// deliberate EXCEPTION to the popup pattern in ROADMAP "Architectural
// foundations" §1 (every other popup in this codebase grabs focus + handles
// Escape itself) -- do not "fix" this to match that pattern.
PanelWindow {
  id: win
  required property ShellScreen screen

  visible: Sv.AccentCtl.panelVisible
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusiveZone: 0

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true

  Rectangle {
    id: card
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: C.Appearance.leftW + 10
    anchors.bottomMargin: C.Appearance.framePadBottom + 48

    width: row.implicitWidth + C.Appearance.popupPad * 2
    height: row.implicitHeight + C.Appearance.popupPad * 1.4

    radius: C.Appearance.bubbleRadius
    antialiasing: true
    clip: true
    color: C.Appearance.popupBg
    border.width: C.Appearance.border
    border.color: C.Appearance.borderCol

    Row {
      id: row
      anchors.centerIn: parent
      spacing: C.Appearance.m6

      Repeater {
        model: Sv.AccentCtl.activeVariants

        delegate: Rectangle {
          readonly property bool active: index === Sv.AccentCtl.activeIndex
          width: label.implicitWidth + 14
          height: label.implicitHeight + 8
          radius: C.Appearance.bubbleRadius * 0.5
          antialiasing: true
          color: active ? C.Appearance.fgA(0.16) : "transparent"
          border.width: active ? 1 : 0
          border.color: C.Appearance.borderCol

          Text {
            id: label
            anchors.centerIn: parent
            text: modelData
            color: active ? C.Appearance.fg : C.Appearance.fgDim
            font.pixelSize: C.Appearance.pillFont
          }
        }
      }
    }
  }
}
