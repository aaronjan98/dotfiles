pragma Singleton
import QtQuick

QtObject {
  // ----- Sizing tokens -----
  property int topH: 40
  property int leftW: 64

  // inner padding for content inside bars
  property int innerPad: 7

  // border ring thickness
  property int border: 1

  // rounding tokens
  property int rSmall: 12
  property int rNormal: 17
  property int rLarge: 25

  // ----- Transparency -----
  property real panelAlpha: 0.72

  // ----- Palette (limerence-ish: blue/purple/violet) -----
  property color bg: Qt.rgba(18/255, 16/255, 28/255, panelAlpha)   // deep violet
  property color borderCol: Qt.rgba(180/255, 175/255, 255/255, 0.22) // soft lavender ring

  // (we'll use these later for active dots, accents, etc.)
  property color accentBlue: "#7aa2f7"
  property color accentViolet: "#a78bfa"
  property color accentPink: "#f0abfc"
  property color fg: "#cfd6ff"
}

