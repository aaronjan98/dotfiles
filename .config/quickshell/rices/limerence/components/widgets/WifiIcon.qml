import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

Item {
  id: root
  implicitWidth: 10
  implicitHeight: 14

  signal clicked()

  function glyph() {
    if (!Sv.WifiNm.wifiEnabled) return "󰤮"   // off
    if (!Sv.WifiNm.connected) return "󰤯"     // no connection
    const s = Sv.WifiNm.strength
    if (s >= 75) return "󰤨"
    if (s >= 50) return "󰤥"
    if (s >= 25) return "󰤢"
    return "󰤟"
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph()
    color: "white"
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

