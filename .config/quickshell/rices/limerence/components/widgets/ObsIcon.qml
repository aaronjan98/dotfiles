import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

// Standalone bar icon for the OBS control popup. A record-circle glyph:
// dim grey when the obs-ctl-daemon can't reach OBS at all, white outline
// when connected but idle, solid red (and pulsing) while OBS is actually
// recording -- so recording state is visible without opening the popup.
Item {
  id: root
  implicitWidth: C.Appearance.topbarIconBoxW
  implicitHeight: C.Appearance.topbarIconBoxH

  readonly property bool recording: Sv.ObsCtl.connected && Sv.ObsCtl.recording.active
  readonly property bool paused: Sv.ObsCtl.connected && Sv.ObsCtl.recording.paused

  signal clicked()
  signal menuRequested()

  Text {
    id: glyph
    anchors.centerIn: parent
    text: (root.recording || root.paused) ? "󰻂" : "󰻃"
    color: !Sv.ObsCtl.connected
      ? Qt.rgba(1, 1, 1, 0.30)
      : root.paused
        ? Qt.rgba(0.95, 0.75, 0.35, 0.95)
        : root.recording
          ? Qt.rgba(0.95, 0.30, 0.30, 0.95)
          : Qt.rgba(1, 1, 1, 0.70)
    font.family: C.Appearance.iconFont
    font.pixelSize: C.Appearance.topbarIconPx

    SequentialAnimation on opacity {
      running: root.recording
      loops: Animation.Infinite
      NumberAnimation { to: 0.45; duration: 650; easing.type: Easing.InOutSine }
      NumberAnimation { to: 1.0; duration: 650; easing.type: Easing.InOutSine }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: (mouse) => {
      if (mouse.button === Qt.RightButton) root.menuRequested()
      else root.clicked()
    }
  }
}
