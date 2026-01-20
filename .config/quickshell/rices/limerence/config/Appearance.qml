pragma Singleton
import QtQuick

QtObject {
  // ---- GLOBAL SCALE ----
  // Set this to match how you want Quickshell to look when Hyprland scale changes.
  // Example: if you switch Hyprland to scale=1.0 and want QS to be bigger, raise uiScale.
  property real uiScale: 1.25

  // Helpers
  // s() = scaled integer pixels (rounded). Great for layout sizes.
  // sr() = scaled real pixels. Great for subtle things (e.g. non-integer spacing if you ever want it).
  function s(px)  { return Math.round(px * uiScale) }
  function sr(px) { return px * uiScale }

  // ---- bar thickness ----
  property int topH: s(24)
  property int leftW: s(26)

  // ---- content frame geometry ----
  property int framePadRight: s(2)
  property int framePadBottom: s(2)
  property int frameRadius: s(7)

  // Keep borders at least 1px so they don't disappear at low scales
  property int border: Math.max(1, s(1))
  // Negative inset is fine; keep it scaled
  property int borderInset: -s(1)

  // ---- palette ----
  property color frameBg: Qt.rgba(20/255, 16/255, 35/255, 0.55)
  property color borderCol: Qt.rgba(210/255, 190/255, 255/255, 0.35)
  property color glow1: Qt.rgba(160/255, 120/255, 255/255, 0.27)
  property color glow2: Qt.rgba(120/255, 190/255, 255/255, 0.12)
  property color glow3: Qt.rgba(255/255, 140/255, 220/255, 0.08)

  // ---- bubbles ----
  property color bubbleBg: Qt.rgba(35/255, 26/255, 60/255, 0.45)
  property int bubbleBorderW: Math.max(1, s(1))
  property int bubblePad: s(6)
  property int bubbleRadius: s(17)
  property int nixBubbleSize: s(30)
  property int nixIconPad: s(3)

  // ---- popups ----
  // More opaque than bubbleBg for readability
  property color popupBg: Qt.rgba(35/255, 26/255, 60/255, 0.95)
  property real popupOverlayA: 0.28

  // Popup geometry tokens used all over Wifi/Bluetooth/Brightness/Power popups
  property int popupPad: s(12)
  property int popupRowGap: s(8)

  // Typical “popup window offset from edges” numbers you use everywhere (+10, +6, etc.)
  property int popupEdgePad: s(10)
  property int popupEdgePadTight: s(6)

  // Common popup widths/heights you’re repeating (360/380/420 etc.)
  property int popupWidth: s(360)
  property int popupWidthWide: s(380)
  property int popupMaxHeight: s(420)

  // ---- pills ----
  property int pillPadX: s(10)
  property int pillPadY: s(2)
  property int pillRadius: 999         // keep as “pill forever”; don’t scale
  property int pillFont: s(10)

  property int pillBorderW: Math.max(1, s(1))
  property color pillBorderCol: Qt.rgba(210/255, 190/255, 255/255, 0.35)

  // ---- workspace island defaults ----
  property int dotSize: s(7)
  property int dotGapH: s(4)
  property int dotGapV: s(6)
  property real pillFactor: 2.1        // ratio; don’t scale
  property int animMsFast: 140         // time; don’t scale

  // ---- generic layout primitives (replace all those 6/8/10/12/14/18/etc.) ----
  property int m2: s(2)
  property int m3: s(3)
  property int m4: s(4)
  property int m6: s(6)
  property int m8: s(8)
  property int m10: s(10)
  property int m12: s(12)
  property int m14: s(14)
  property int m18: s(18)
  property int m20: s(20)
  property int m24: s(24)
  property int m28: s(28)
  property int m32: s(32)
  property int m34: s(34)
  property int m44: s(44)

  // Dividers used in topbar pills (width 1, height 14)
  property int dividerW: Math.max(1, s(1))
  property int dividerH: s(14)

  // ---- icon sizing ----
  // Many of your icon widgets are hardcoded to 10x14 with font size 14.
  property int topbarIconBoxW: s(10)
  property int topbarIconBoxH: s(14)
  property int topbarIconPx: s(14)

  // Icons in pills are often a bit bigger than text
  property int pillIconPx: pillFont + s(4)

  // ---- fonts ----
  property string iconFont: "Symbols Nerd Font"
}

