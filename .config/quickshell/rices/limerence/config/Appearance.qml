pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: appearance

  // ---- GLOBAL SCALE ----
  // Driven by QS_UI_SCALE env var set per-host in NixOS (hosts/<name>/configuration.nix).
  // ThinkPad omits the var and falls back to 1.25; Framework 13 sets 1.75.
  property real uiScale: parseFloat(Quickshell.env("QS_UI_SCALE") || "1.25")

  // External monitor scale: Hyprland already scales DP-1 at 1.6×, so QML should use
  // uiScale / 1.6 to avoid double-scaling (otherwise bars appear ~2.8× base size).
  property real externalUiScale: uiScale / 1.6
  // Visual scale for external frame chrome. Full DP-1 compensation is too small,
  // while laptop scale is too large, so keep this as a direct tuning knob.
  property real externalFrameScale: 0.8
  // The corner bubble reads larger than the menu islands on DP-1, so tune it separately.
  property real externalCornerScale: 0.7

  // Helpers
  // s()  = scaled integer pixels for the laptop screen
  // se() = scaled integer pixels for the external screen (compensates for Hyprland's 1.6× scale)
  // sr() = scaled real pixels (laptop). For subtle non-integer spacing.
  function s(px)  { return Math.round(px * uiScale) }
  function se(px) { return Math.round(px * externalUiScale) }
  function sr(px) { return px * uiScale }

  // ---- bar thickness ----
  property int topH: s(24)
  // Framework topbar gets a small extra vertical cushion.
  property int topHFramework: Math.round(topH + s(6))
  // External topbar keeps 0.8x content but gets extra vertical breathing room.
  property int topHExternal: Math.round((topH + s(8)) * externalFrameScale)
  property int leftW: nixBubbleSize

  // ---- content frame geometry ----
  property int framePadTopFramework: s(3)
  property int framePadLeftExternal: s(2)
  property int framePadRight: s(2)
  property int framePadRightFramework: s(4)
  property int framePadBottom: s(2)
  property int framePadBottomFramework: s(4)
  property int frameRadius: s(7)

  // Keep borders at least 1px so they don't disappear at low scales
  property int border: Math.max(1, s(1))
  // Negative inset is fine; keep it scaled
  property int borderInset: -s(1)

  // ---- wallpaper-derived palette ----
  // matugen writes ~/.cache/quickshell/colors.json on every wallpaper change (see
  // ~/.config/matugen/config.toml and the set-wallpapers hook), then pokes us over
  // IPC (below) to re-read it — so a new wallpaper recolours the shell live, no
  // reload. The scheme follows the wallpaper: set-wallpapers picks matugen
  // --mode light/dark by luminance, giving a light theme (light panels + dark
  // text, via `fg`) on light wallpapers and the dark theme on dark ones. If the
  // file is missing or caught mid-write, every role falls back to the original
  // hand-picked purple (dark) palette, so the shell always has valid colours.
  property var palette: ({})
  property FileView _paletteFile: FileView {
    path: Quickshell.env("HOME") + "/.cache/quickshell/colors.json"
    // watchChanges is unreliable here: matugen writes the file atomically (temp +
    // rename), which replaces the inode and defeats the file watch. Instead,
    // set-wallpapers pokes us over IPC after it regenerates the palette (see the
    // IpcHandler below), and we reload() explicitly. onLoaded still fires on first
    // load and on every reload() call.
    onLoaded:     appearance.palette = _parse(text())
    onLoadFailed: appearance.palette = ({})
    function _parse(t) {
      try { return JSON.parse(t) || ({}) }
      catch (e) { return appearance.palette }   // keep last good on a partial write
    }
  }

  // set-wallpapers calls `qs ipc call palette reload` after matugen rewrites
  // colors.json, which re-reads the file and recolours the shell live.
  property IpcHandler _paletteIpc: IpcHandler {
    target: "palette"
    function reload(): void { appearance._paletteFile.reload() }
  }

  // Opaque colour for a matugen role, else the fallback hex.
  function _c(role, fallbackHex) {
    var v = palette[role]
    var hex = (typeof v === "string" && /^#?[0-9A-Fa-f]{6}$/.test(v)) ? v : fallbackHex
    return Qt.color(hex)
  }
  // Same role, with an explicit alpha layered on.
  function _rgba(role, fallbackHex, a) {
    var c = _c(role, fallbackHex)
    return Qt.rgba(c.r, c.g, c.b, a)
  }

  // Which scheme matugen gave us. set-wallpapers picks --mode by wallpaper
  // luminance, so on a light wallpaper `on_surface` comes back DARK and on a dark
  // wallpaper it comes back LIGHT. Deriving the mode from the text colour means the
  // shell needs no extra flag and flips with the palette file alone.
  readonly property color fg: _c("on_surface", "#f2ecff")   // primary text/icon colour
  // Foreground at an arbitrary alpha — for dimmed text, subtle chip fills and hairline
  // borders that used to be hardcoded Qt.rgba(1,1,1,α). Using fg means they are light
  // over the dark scheme (≈ the old white) and dark over the light scheme (so they
  // actually show), instead of white-on-white.
  function fgA(a) { return Qt.rgba(fg.r, fg.g, fg.b, a) }
  readonly property color fgDim: fgA(0.60)
  readonly property bool isDark: (0.299*fg.r + 0.587*fg.g + 0.114*fg.b) > 0.5

  // ---- palette (wallpaper-driven hues; fallbacks == the original purple theme) ----
  // Light panels need more opacity than dark ones to register over a light
  // wallpaper and give the (now dark) text a stable backdrop — hence the per-mode
  // alpha. Surfaces themselves flip automatically (matugen `surface` is dark in
  // dark mode, light in light mode).
  // Alphas tuned for a frosted-glass look: a Hyprland `layerrule = blur, quickshell`
  // blurs the wallpaper behind these panels, so they can stay quite translucent and
  // still read as solid glass rather than a flat wash. Light mode is kept a touch
  // more transparent than before (it looked chalky-white) now that blur backs it.
  property color frameBg:   _rgba("surface",   "#141023", isDark ? 0.45 : 0.42)
  property color borderCol: _rgba("primary",   "#d2beff", isDark ? 0.35 : 0.50)
  property color glow1:     _rgba("primary",   "#a078ff", isDark ? 0.27 : 0.22)
  property color glow2:     _rgba("tertiary",  "#78beff", isDark ? 0.12 : 0.14)
  property color glow3:     _rgba("secondary", "#ff8cdc", isDark ? 0.08 : 0.10)

  // ---- bubbles ----
  // Islands (bar pills, bubbles, notifications) sit a clear step up the tonal
  // ladder from the frame backdrop (surface) and are more opaque than it (0.62 >
  // frameBg's 0.55) so they read as raised chips rather than translucent patches.
  property color bubbleBg: _rgba("surface_container_high", "#2a2047", isDark ? 0.55 : 0.55)
  property int bubbleBorderW: Math.max(1, s(1))
  property int bubblePad: s(6)
  property int bubbleRadius: s(17)
  property int nixBubbleSize: s(30)
  property int nixIconPad: s(3)

  // ---- popups ----
  // More opaque than bubbleBg for readability, and one tone above the islands so a
  // popup still separates from any island chips inside it.
  property color popupBg: _rgba("surface_container_highest", "#2f2452", isDark ? 0.82 : 0.80)
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
  property color pillBorderCol: _rgba("primary", "#d2beff", 0.35)

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

  // ---- wired icon (nerd font) ----
  // Replace this glyph string with the wired glyph you prefer from your nerd font.
  property string wiredIcon: "󰈚"
}


