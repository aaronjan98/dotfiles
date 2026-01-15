pragma Singleton
import QtQuick

QtObject {
  // ---- bar thickness ----
  property int topH: 30
  property int leftW: 28

  // ---- content frame geometry ----
  property int framePadRight: 2
  property int framePadBottom: 2
  property int frameRadius: 7
  property int border: 1
  property int borderInset: -1

  // ---- palette ----
  property color frameBg: Qt.rgba(20/255, 16/255, 35/255, 0.55)
  property color borderCol: Qt.rgba(210/255, 190/255, 255/255, 0.35)
  property color glow1: Qt.rgba(160/255, 120/255, 255/255, 0.27)
  property color glow2: Qt.rgba(120/255, 190/255, 255/255, 0.12)
  property color glow3: Qt.rgba(255/255, 140/255, 220/255, 0.08)

  // ---- bubbles ----
  property color bubbleBg: Qt.rgba(35/255, 26/255, 60/255, 0.45)
  property int bubbleBorderW: 1
  property int bubblePad: 6
  property int bubbleRadius: 17
  property int nixBubbleSize: 30
  property int nixIconPad: 3

  // ---- pills ----
  property int pillPadX: 10
  property int pillPadY: 3
  property int pillRadius: 999
  property int pillFont: 10

  // make pills visible on dark wallpapers
  property int pillBorderW: 1
  property color pillBorderCol: Qt.rgba(210/255, 190/255, 255/255, 0.35)

  // ---- fonts ----
  // After installing nerd-fonts.symbols-only, set to exactly what fc-list shows.
  property string iconFont: "Symbols Nerd Font"
}

