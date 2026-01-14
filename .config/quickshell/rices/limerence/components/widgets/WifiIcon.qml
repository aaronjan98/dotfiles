import QtQuick
import "../../config" as C
import "../services" as Sv

Item {
  id: root
  signal clicked()

  property int size: C.Appearance.pillFont + 8

  implicitWidth: size
  implicitHeight: size

  function glyph() {
    if (!Sv.WifiNm.ok) return "󰤭"
    if (!Sv.WifiNm.wifiEnabled) return "󰤮"
    if (!Sv.WifiNm.connected) return "󰤯"

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
    font.pixelSize: root.size
    font.family: C.Appearance.iconFont
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}

