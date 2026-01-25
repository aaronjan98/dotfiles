import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

Item {
  id: root
  implicitWidth: C.Appearance.topbarIconBoxW
  implicitHeight: C.Appearance.topbarIconBoxH

  signal clicked()

  function glyph() {
    // If the system is actually routing via ethernet, show ethernet icon.
    if (Sv.WifiNm.activeType === "ethernet")
      return "󰈀"  // ethernet (Nerd Font / MDI)

    // Otherwise fall back to Wi-Fi status
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
    opacity: (Sv.WifiNm.activeType === "ethernet")
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

