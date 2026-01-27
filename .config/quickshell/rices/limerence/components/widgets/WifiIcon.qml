import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

Item {
  id: root
  implicitWidth: C.Appearance.topbarIconBoxW
  implicitHeight: C.Appearance.topbarIconBoxH

  signal clicked()

  function glyph() {
    const t = (Sv.WifiNm.activeType || "").toLowerCase()

    if (t === "ethernet")
      return "󰈀"

    if (t === "unknown" && (Sv.WifiNm.activeDevice || "").length > 0)
      return "󰲝"

    if (!Sv.WifiNm.wifiEnabled)
      return "󰤮"   // radio off

    if (!Sv.WifiNm.connected)
      return "󰤯"   // disconnected

    const s = Sv.WifiNm.strength | 0
    if (s <= 0)  return "󰤟"
    if (s >= 70) return "󰤨"
    if (s >= 50) return "󰤥"
    if (s >= 25) return "󰤢"
    return "󰤟"
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph()
    color: "white"
    font.family: C.Appearance.iconFont
    font.pixelSize: C.Appearance.topbarIconPx

    // Slightly dim when not connected / off (but keep ethernet fully bright)
    opacity: ((Sv.WifiNm.activeType || "").toLowerCase() === "ethernet")
      ? 1.0
      : ((!Sv.WifiNm.wifiEnabled || !Sv.WifiNm.connected) ? 0.75 : 1.0)
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}

