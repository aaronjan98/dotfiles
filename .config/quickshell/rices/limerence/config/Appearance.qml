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

  // ---- wallpaper "intensity" (adaptive panel opacity / blur) ----
  // set-wallpapers measures each wallpaper (mean luminance + stddev = brightness +
  // busyness) and writes a 0..1 `intensity` here: higher for brighter and/or busier
  // wallpapers, i.e. the ones that fight panel legibility hardest. Panels get more
  // opaque as it rises (see _solid() below); the same script also drives Hyprland's
  // blur strength from it, so blur and opacity move together. A missing/!parsed file
  // leaves a neutral middle so the shell still looks right before the first set.
  property real wallIntensity: 0.6
  // Raw mean luminance of the wallpaper (0..1), used on its own to key the recess
  // shadow (see frameHiA) — brightness, unlike intensity, isn't inflated by busyness.
  property real wallLum: 0.5
  property FileView _surfaceFile: FileView {
    path: Quickshell.env("HOME") + "/.cache/quickshell/surface.json"
    onLoaded: {
      try {
        var o = JSON.parse(text())
        if (o && typeof o.intensity === "number") appearance.wallIntensity = o.intensity
        if (o && typeof o.luminance === "number") appearance.wallLum = o.luminance
      } catch (e) { /* keep last good on a partial write */ }
    }
  }

  // Renormalise intensity to 0..1 across the band real wallpapers span (0.30 dark/calm
  // .. 0.78 where the current sakura wallpaper lands). _byWall() then lerps a value from
  // its DARK-wallpaper end to its LIGHT-wallpaper end as intensity rises. Bright/busy
  // wallpapers get heavy blur (see set-wallpapers), so panels go MORE transparent there:
  // the frosted bright wallpaper is itself the light backdrop, and piling a solid panel
  // on top of it just reads as a white block. Dark wallpapers keep more opaque panels.
  readonly property real _wallT: {
    var t = (wallIntensity - 0.30) / (0.78 - 0.30)
    return t < 0 ? 0 : (t > 1 ? 1 : t)
  }
  function _byWall(darkEnd, lightEnd) { return darkEnd + (lightEnd - darkEnd) * _wallT }

  // set-wallpapers calls `qs ipc call palette reload` after matugen rewrites
  // colors.json; we re-read both the palette and the surface/intensity file so a new
  // wallpaper recolours AND re-opacifies the shell live.
  property IpcHandler _paletteIpc: IpcHandler {
    target: "palette"
    function reload(): void {
      appearance._paletteFile.reload()
      appearance._surfaceFile.reload()
    }
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
  // Content-frame fill: FROSTED GLASS tinted to the wallpaper's dominant colour. `source`
  // is matugen's seed — the extracted dominant tone of the wallpaper (e.g. salmon for this
  // one), and it flips dark automatically for dark wallpapers. A moderate opacity keeps it
  // semi-transparent AND above the `ignorealpha 0.1` cutoff so Hyprland frosts the
  // wallpaper behind it (the blurry look), while the tint matches the wallpaper so it reads
  // cohesive rather than a grey block. The recess shadow (frameHiA) then reads as an inset
  // on this frosted surface.
  // Semi-opaque wallpaper-tinted overlay, like main's 0.55 frame but in the wallpaper's
  // dominant colour (`source`) so it's light on light wallpapers instead of main's dark
  // purple. Kept BELOW the `ignorealpha 0.55` cutoff (30-look.conf) so it is NOT frosted —
  // a sharp see-through overlay, no gloss. At ~0.5 opacity it's a real surface, so the
  // recess shadow reads as a soft inset rather than a floating band.
  property color frameBg:   _rgba("source",    "#141023", 0.50)
  property color borderCol: _rgba("primary",   "#d2beff", isDark ? 0.35 : 0.50)
  property color glow1:     _rgba("primary",   "#a078ff", isDark ? 0.27 : 0.22)
  property color glow2:     _rgba("tertiary",  "#78beff", isDark ? 0.12 : 0.14)
  property color glow3:     _rgba("secondary", "#ff8cdc", isDark ? 0.08 : 0.10)

  // ---- bubbles ----
  // Islands (bar pills, bubbles, notifications) sit a clear step up the tonal
  // ladder from the frame backdrop (surface) and are more opaque than it (0.62 >
  // frameBg's 0.55) so they read as raised chips rather than translucent patches.
  // Islands are translucent glass: the Hyprland `layerrule = blur, quickshell` frosts
  // the wallpaper behind this low-opacity fill, so the pills read as frosted glass
  // rather than flat chips (no bevel gradient). Notifications override this alpha for
  // readability, so lowering it here only affects the bar islands/bubbles.
  // Islands go FULLY TRANSPARENT on bright wallpapers. Key mechanism: the
  // `layerrule = ignorealpha 0.1, quickshell` means Hyprland skips the blur wherever the
  // panel is >~90% transparent — so an island at alpha 0 shows the RAW, unblurred,
  // un-dimmed wallpaper and matches it exactly (bright). The earlier darkness came from
  // alpha ~0.2, ABOVE that 0.1 cutoff, where the island got the blur (dimmed for ghostty)
  // and read dark. So ramp the island fill to 0 on bright wallpapers (pills become their
  // border + text floating on the wallpaper) and keep the dark-wallpaper end frosted
  // (0.40 surface_container_high) where a translucent dark fill over blur looks right.
  property color bubbleBg: _rgba(isDark ? "surface_container_high" : "surface", "#2a2047", _byWall(0.40, 0.0))

  // Content-frame edge curvature: the inner lip catches light toward the content edge
  // (brightest at the lip, fading out into the frame), so the edge reads as a soft
  // rounded roll curving into the content. This is the peak alpha at the very lip.
  // Recess-shadow strength keyed to the wallpaper's BRIGHTNESS (wallLum), not the
  // combined intensity: a near-white wallpaper makes the light frame so pale that even
  // a faint black band reads as stark, so keep it subtle; a less-white / busier /
  // darker wallpaper (lower luminance) can carry a darker shadow. Keying off luminance
  // rather than intensity (which busyness also inflates) means a busy wallpaper gets a
  // *stronger* shadow, not a weaker one. Linear + clamped so it never vanishes or
  // gets heavy: ~0.10 over white, ~0.28 over dark.
  readonly property real frameHiA: {
    // Peak shadow alpha at the content-frame edge, keyed to wallpaper LUMINANCE (wallLum,
    // 0..1 from surface.json). A dark recess reads stark over a light wallpaper, so fade
    // it right down on pale ones (~0.19 at wallLum 0.69) and let it go strong on dark ones
    // (up to 0.60) where it would otherwise disappear. Linear + clamped.
    var a = 0.78 - 0.85 * wallLum;
    return a < 0.15 ? 0.15 : (a > 0.60 ? 0.60 : a);
  }
  // Colour of the edge roll. Black reads as a true shadow (content recessed into a shaded
  // well); see recess-shadow.frag, which hardcodes black — this is kept for reference.
  readonly property color frameRollColor: "#000000"
  // How far (px) the outset shadow reaches from the content-frame edge into the frame
  // (recess-shadow.frag `span`). Deliberately LARGER than the thick top/left edges (~53px)
  // so the shadow is still fading when it hits the screen edge and "bleeds off" instead of
  // ending inside the frame (no floating band); on the thin right/bottom trim the overshoot
  // keeps the visible near-edge part from collapsing into an invisible sliver.
  readonly property int frameRollSpan: 65
  // Falloff exponent of the outset shadow (recess-shadow.frag `peakFrac`): darkest right at
  // the content-frame edge, tapering outward. Higher = mass skewed harder toward the edge.
  readonly property real frameRollEase: 2.0
  readonly property real frameRollTail: 1.25   // unused; kept for reference
  property int bubbleBorderW: Math.max(1, s(1))
  property int bubblePad: s(6)
  property int bubbleRadius: s(17)
  property int nixBubbleSize: s(30)
  property int nixIconPad: s(3)

  // ---- popups ----
  // More opaque than bubbleBg for readability, and one tone above the islands so a
  // popup still separates from any island chips inside it.
  property color popupBg: _rgba("surface_container_highest", "#2f2452", _byWall(0.82, 0.74))
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


