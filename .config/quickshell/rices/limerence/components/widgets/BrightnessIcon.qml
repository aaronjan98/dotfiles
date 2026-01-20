import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

Item {
  id: root
  implicitWidth: C.Appearance.topbarIconBoxW
  implicitHeight: C.Appearance.topbarIconBoxH

  signal clicked()

  function glyph() {
    if (!Sv.BrightnessCtl.ok || !Sv.BrightnessCtl.screenDev) return "󰃚"
    const p = Sv.BrightnessCtl.screenPercent

    // 7 levels: 0..100
    if (p <= 0)  return "󰃚"
    if (p < 17)  return "󰃛"
    if (p < 34)  return "󰃜"
    if (p < 50)  return "󰃝"
    if (p < 67)  return "󰃞"
    if (p < 84)  return "󰃟"
    return "󰃠"
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph()
    color: "white"
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

