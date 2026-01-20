import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

Item {
  id: root

  implicitWidth: box.implicitWidth
  implicitHeight: box.implicitHeight
  width: implicitWidth
  height: implicitHeight

  // How many % per scroll notch (behavior, do not scale)
  property int step: 5

  function glyph() {
    if (!Sv.VolumeCtl || !Sv.VolumeCtl.ok) return "󰖁"
    if (Sv.VolumeCtl.muted) return "󰖁"
    if (Sv.VolumeCtl.headphones) return "󰋋"

    var p = Sv.VolumeCtl.percent
    if (p <= 0) return "󰖁"
    if (p < 35) return "󰕿"
    if (p < 70) return "󰖀"
    return "󰕾"
  }

  Item {
    id: box
    anchors.centerIn: parent
    implicitWidth: row.width
    implicitHeight: row.height

    Row {
      id: row
      spacing: C.Appearance.m6

      Text {
        text: root.glyph()
        color: "white"
        font.family: C.Appearance.iconFont
        font.pixelSize: C.Appearance.pillIconPx   // scaled icon size
      }

      Text {
        visible: Sv.VolumeCtl && Sv.VolumeCtl.ok
        text: Sv.VolumeCtl ? (Sv.VolumeCtl.percent + "%") : ""
        color: "white"
        font.pixelSize: C.Appearance.pillFont
      }
    }
  }

  // Optional: scroll to change volume (and auto-unmute)
  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: (event) => {
      if (!Sv.VolumeCtl) return
      var dy = event.angleDelta.y
      if (dy === 0) return
      Sv.VolumeCtl.setDelta(dy > 0 ? root.step : -root.step)
      event.accepted = true
    }
  }
}

