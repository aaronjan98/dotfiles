import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

// Standalone bar icon (not inside a pill) for the live note-taking recorder.
// A plain paperclip glyph; click toggles recording directly -- no popup.
// Fold-in/summarize happens entirely through conversation with the agent
// (notetake-foldin.sh), not through this icon. While recording, the glyph
// rotates 90 degrees counterclockwise and holds there; it rotates back to
// resting position when recording stops.
Item {
  id: root
  implicitWidth: C.Appearance.topbarIconBoxW
  implicitHeight: C.Appearance.topbarIconBoxH

  readonly property bool recording: Sv.NotetakeCtl.recording

  Text {
    id: glyph
    anchors.centerIn: parent
    text: "" // nf-fa-paperclip
    color: root.recording ? Qt.rgba(0.85, 0.65, 0.35, 0.9) : Qt.rgba(1, 1, 1, 0.70)
    font.family: C.Appearance.iconFont
    font.pixelSize: C.Appearance.topbarIconPx
    rotation: root.recording ? -90 : 0

    Behavior on rotation {
      NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: Sv.NotetakeCtl.toggle()
  }
}
