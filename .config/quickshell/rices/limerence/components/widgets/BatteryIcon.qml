import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

Item {
  id: root

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight
  width: implicitWidth
  height: implicitHeight

  // 0..1 animation phase used only while charging (for “breathing”)
  property real chargePhase: 0.0

  // Smoothly animate chargePhase when charging
  SequentialAnimation on chargePhase {
    id: chargeAnim
    running: Sv.BatterySys && Sv.BatterySys.ok && Sv.BatterySys.isCharging
    loops: Animation.Infinite

    NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
    NumberAnimation { to: 0.0; duration: 1200; easing.type: Easing.InOutSine }
  }

  // -------- glyph selection --------
  function dischargingGlyph(p) {
    // your 10-step set (0..100)
    if (p >= 90) return "󰁹"
    if (p >= 80) return "󰂂"
    if (p >= 70) return "󰂁"
    if (p >= 60) return "󰂀"
    if (p >= 50) return "󰁿"
    if (p >= 40) return "󰁾"
    if (p >= 30) return "󰁽"
    if (p >= 20) return "󰁼"
    if (p >= 10) return "󰁻"
    if (p >= 0)  return "󰁺"
    return "󰂃"
  }

  function chargingGlyph(p) {
    // your charging 10-step set
    if (p >= 90) return "󰂅"
    if (p >= 80) return "󰂋"
    if (p >= 70) return "󰂊"
    if (p >= 60) return "󰢞"
    if (p >= 50) return "󰂉"
    if (p >= 40) return "󰢝"
    if (p >= 30) return "󰂈"
    if (p >= 20) return "󰂇"
    if (p >= 10) return "󰂆"
    if (p >= 0)  return "󰢜"
    return "󰂃"
  }

  function glyph() {
    if (!Sv.BatterySys || !Sv.BatterySys.ok) return "󰂎" // unknown
  
    const p = Sv.BatterySys.percent
  
    // Full battery glyph (even if plugged in)
    if (Sv.BatterySys.isFull) return "󱈏"
  
    // Charging glyph ladder
    if (Sv.BatterySys.isCharging) return chargingGlyph(p)
  
    // Discharging glyph ladder
    return dischargingGlyph(p)
  }

  // -------- color logic --------
  // Basic continuous red->green based on percent (0..100)
  function baseColorForPercent(p) {
    // clamp
    var t = Math.max(0, Math.min(1, p / 100.0))

    // a simple RGB lerp: red -> green
    // (you can swap to HSV if you want different feel)
    var r = (1.0 - t) * 1.0 + t * 0.35
    var g = (1.0 - t) * 0.25 + t * 1.0
    var b = (1.0 - t) * 0.25 + t * 0.55

    return Qt.rgba(r, g, b, 0.95)
  }

  // When charging, “breathe” toward a brighter, slightly warmer tint.
  function chargingColor(p) {
    var base = baseColorForPercent(p)

    // target glow color: a little brighter & warmer
    var glow = Qt.rgba(
      Math.min(1.0, base.r + 0.18),
      Math.min(1.0, base.g + 0.18),
      Math.min(1.0, base.b + 0.10),
      0.98
    )

    // blend base -> glow by chargePhase (0..1)
    var a = root.chargePhase
    return Qt.rgba(
      base.r * (1 - a) + glow.r * a,
      base.g * (1 - a) + glow.g * a,
      base.b * (1 - a) + glow.b * a,
      base.a * (1 - a) + glow.a * a
    )
  }

  function iconColor() {
    if (!Sv.BatterySys || !Sv.BatterySys.ok) return Qt.rgba(1, 1, 1, 0.85)
    const p = Sv.BatterySys.percent
    if (Sv.BatterySys.isCharging) return chargingColor(p)
    return baseColorForPercent(p)
  }

  Row {
    id: row
    spacing: 6
    anchors.centerIn: parent

    // Battery icon (colored)
    Text {
      text: root.glyph()
      color: root.iconColor()
      font.family: C.Appearance.iconFont
      font.pixelSize: C.Appearance.pillFont + 4
    }

    // Percent (always white)
    Text {
      visible: Sv.BatterySys && Sv.BatterySys.ok
      text: Sv.BatterySys ? (Sv.BatterySys.percent + "%") : ""
      color: "white"
      font.pixelSize: C.Appearance.pillFont
    }
  }
}

