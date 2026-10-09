import QtQuick
import "../../config" as C

// Standalone bar icon (not inside a pill) for clipboard history.
// Mirrors WifiIcon/BluetoothIcon: just a glyph that emits clicked() --
// TopBar owns the open/close state and the ClipboardPopup component.
Item {
  id: root
  implicitWidth: C.Appearance.topbarIconBoxW
  implicitHeight: C.Appearance.topbarIconBoxH

  signal clicked()

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
    onClicked: root.clicked()
  }
}
