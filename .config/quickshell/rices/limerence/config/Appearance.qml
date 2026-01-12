pragma Singleton
import QtQuick

QtObject {
  // ---- bar thickness ----
  property int topH: 24
  property int leftW: 26

  // ---- content frame geometry ----
  property int framePadRight: 2
  property int framePadBottom: 2

  // The hole radius (content cutout)
  property int frameRadius: 7

  // Border ring thickness + where to place it INSIDE the hole
  property int border: 1
  property int borderInset: -2

  // ---- palette (make it readable while testing) ----
  // This is the "ring tint" color (outside the hole). Lower alpha = subtler.
  property color frameBg: Qt.rgba(20/255, 16/255, 35/255, 0.35)

  // Crisp inner border line
  property color borderCol: Qt.rgba(210/255, 190/255, 255/255, 0.35)

  // inward glow strokes
  property color glow1: Qt.rgba(160/255, 120/255, 255/255, 0.27)
  property color glow2: Qt.rgba(120/255, 190/255, 255/255, 0.12)
  property color glow3: Qt.rgba(255/255, 140/255, 220/255, 0.08)

  // ---- bubbles ----
  property color bubbleBg: Qt.rgba(35/255, 26/255, 60/255, 0.90)
  property color bubbleBorder: Qt.rgba(210/255, 190/255, 255/255, 0.25)
  property int bubblePad: 4

  // Nix bubble sizing
  property int nixBubbleSize: 35     // size of the square bubble
  property int nixIconPad: 5         // padding inside the bubble
}

