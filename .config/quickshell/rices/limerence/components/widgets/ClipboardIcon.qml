import QtQuick
import Quickshell.Io
import "../../config" as C

// Standalone bar icon (not inside a pill) for clipboard history.
// Mirrors NotetakeIcon's shape: a plain glyph, click runs the same
// cliphist/fz/wl-copy pipeline bound to Super+Ctrl+V in Hyprland
// (~/.config/hypr/conf.d/20-binds.conf) -- no popup, just fires the picker.
Item {
  id: root
  implicitWidth: C.Appearance.topbarIconBoxW
  implicitHeight: C.Appearance.topbarIconBoxH

  Process {
    id: proc
    command: ["sh", "-c", "cliphist list | ~/.config/hypr/scripts/fz -d | cliphist decode | wl-copy"]
  }

  Text {
    anchors.centerIn: parent
    text: "󰅌" // nf-md-clipboard_outline
    color: Qt.rgba(1, 1, 1, 0.70)
    font.family: C.Appearance.iconFont
    font.pixelSize: C.Appearance.topbarIconPx
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: { proc.running = false; proc.running = true }
  }
}
