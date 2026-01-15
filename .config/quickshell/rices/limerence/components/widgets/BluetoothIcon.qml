import QtQuick
import "../../config" as C
import Quickshell.Bluetooth

Item {
  id: root
  implicitWidth: 12
  implicitHeight: 14

  signal clicked()

  function isEnabled() {
    const ad = Bluetooth.defaultAdapter
    return ad ? ad.enabled : false
  }

  function connectedAny() {
    const ds = Bluetooth.devices ? Bluetooth.devices.values : []
    for (let i = 0; i < ds.length; i++) {
      if (ds[i] && ds[i].connected) return true
    }
    return false
  }

  function glyph() {
    if (!isEnabled()) return "󰂲" // bluetooth off
    return "󰂯"                    // bluetooth on
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph()
    color: root.isEnabled()
      ? (root.connectedAny() ? Qt.rgba(1,1,1,1) : Qt.rgba(1,1,1,0.85))
      : Qt.rgba(1,1,1,0.55)

    font.family: C.Appearance.iconFont
    font.pixelSize: 14
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}

