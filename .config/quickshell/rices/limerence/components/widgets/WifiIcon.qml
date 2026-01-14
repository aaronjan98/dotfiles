import QtQuick
import "../../config" as C
import "../services" as Sv

Item {
  id: root

  // You can flip this if you ever want to use glyphs instead
  property bool preferSvg: true

  // icon size
  property int size: C.Appearance.pillFont + 8

  implicitWidth: size
  implicitHeight: size

  function svgForState() {
    if (!Sv.WifiNm.ok) return "wifi-error.svg"
    if (!Sv.WifiNm.wifiEnabled) return "no-wifi.svg"
    if (!Sv.WifiNm.connected) return "no-wifi.svg"

    const s = Sv.WifiNm.strength
    if (s >= 75) return "wifi-4-bars.svg"
    if (s >= 50) return "wifi-3-bars.svg"
    if (s >= 25) return "wifi-2-bars.svg"
    return "wifi-1-bar.svg"
  }

  function glyphForState() {
    if (!Sv.WifiNm.ok) return "!"
    if (!Sv.WifiNm.wifiEnabled) return "󰤮"
    if (!Sv.WifiNm.connected) return "󰤯"
    const s = Sv.WifiNm.strength
    if (s >= 75) return "󰤨"
    if (s >= 50) return "󰤥"
    if (s >= 25) return "󰤢"
    return "󰤟"
  }

  // SVG
  Image {
    id: svg
    visible: root.preferSvg
    anchors.centerIn: parent
    width: root.size
    height: root.size
    source: "qs:@/qs/assets/icons/wifi/" + root.svgForState()
    fillMode: Image.PreserveAspectFit
    smooth: true

    // Optional: dim when disconnected/off
    opacity: (!Sv.WifiNm.ok) ? 1.0
      : (!Sv.WifiNm.wifiEnabled) ? 0.35
      : (Sv.WifiNm.connected ? 1.0 : 0.55)
  }

  // Glyph fallback (also useful for debugging)
  Text {
    id: glyph
    visible: !root.preferSvg
    anchors.centerIn: parent
    text: root.glyphForState()
    color: "white"
    font.pixelSize: root.size
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    // Simple + reliable actions for now
    onClicked: Sv.WifiNm.toggleWifi(!Sv.WifiNm.wifiEnabled)
    onPressAndHold: Sv.WifiNm.disconnect()
  }
}

