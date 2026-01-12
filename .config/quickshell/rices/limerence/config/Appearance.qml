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
  property color frameBg: Qt.rgba(20/255, 16/255, 35/255, 0.55)

  // Crisp inner border line
  property color borderCol: Qt.rgba(210/255, 190/255, 255/255, 0.35)

  // inward glow strokes
  property color glow1: Qt.rgba(160/255, 120/255, 255/255, 0.27)
  property color glow2: Qt.rgba(120/255, 190/255, 255/255, 0.12)
  property color glow3: Qt.rgba(255/255, 140/255, 220/255, 0.08)

  // ---- bubbles ----
  // property color bubbleBg: Qt.rgba(35/255, 26/255, 60/255, 0.90)
  // property color bubbleBg: Qt.rgba(12/255, 10/255, 22/255, 0.90)  // deep ink
  // property color bubbleBg: Qt.rgba(10/255, 14/255, 28/255, 0.92)  // deep navy violet
  property color bubbleBg: Qt.rgba(18/255, 8/255, 22/255, 0.92)   // blackberry


  property int bubbleBorderW: 1
  // property color bubbleBorderCol: Qt.rgba(210/255, 190/255, 255/255, 0.75)

  property int bubblePad: 4
  property int bubbleRadius: 7

  // If you set this, your CornerPatch window must also be that big or it will clip.
  property int nixBubbleSize: 27
  property int nixIconPad: 1
}

