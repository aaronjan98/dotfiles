# 2026-10-23 — content-frame recess shadow rebuilt as an SDF shader (10:44 PDT)

Branch: `quickshell-frame-shape` (dotfiles). Continuation of the 2026-10-08 frame
work — this session **resolved the "NOT fixed" note** from that entry (thin
right/bottom frame edges clipped the recess roll). Commit this session: `cb076e1`
(nothing pushed / merged to main). Terminal/bedtime/nix work from the same long
session was already committed earlier (`7a41f42`, `9e52b85`, `4eca52f`, `2185e18`,
`554da1e`, etc.).

## What was worked on
Replaced the stacked glow-ring recess "roll" with **one signed-distance-field
`ShaderEffect`** in `components/frame/ContentFrame.qml`, and made it look right on
all four edges + corners, un-blurred, wallpaper-adaptive. See the new doc section
`rices/limerence/docs/appearance-and-scaling.md` → "Content-frame recess shadow".

Files: `components/frame/recess-shadow.frag` + `.vert` (+ compiled `.qsb`),
`ContentFrame.qml`, `config/Appearance.qml`, `hypr/conf.d/30-look.conf`.

## The geometry that made this hard (the real crux)
Spent most of the session fighting the wrong mental model. Ground truth (from
`hyprctl` on eDP-1, Framework, `QS_UI_SCALE=1.75` so `s(30)=53`):
- **Frame fill is asymmetric**: thick top/left ~53px (the bars reserve it,
  `reserved=[53,53,0,0]`; `topHFramework`/`leftW`), **thin right/bottom ~4px**
  (`framePadRight`/`framePadBottom = s(2)`).
- **The content window floats *inside* the hole with ~100px gaps on every side** —
  terminals (ghostty/kitty) cell-quantise their size and Hyprland centres them, so
  the window never fills the hole. The frame overlay has `exclusiveZone 0`, so
  changing `framePad*` does **not** move the window; it only paints more/less tint
  over the wallpaper gap.
- Therefore **no hole-anchored shadow can hug the window** — it hugs the frame (hole)
  edge, which IS what the user calls "the content frame". The glowing rounded-rect
  border the user sees = the hole edge (glow rings in `inner`), with the Hyprland
  window border (the orange/red gradient) a separate thing further in.

## Key insight / decision: fixed-span "bleed-off", not normalised
The winning model (user's own suggestion: *"make the shader think the frame goes
further than the screen"*):
- **Outset** shadow, darkest at the content-frame edge (`d=0`), fading outward:
  `a = maxAlpha * pow(1 - clamp(d/span,0,1), peakFrac)`, premultiplied black.
- **`span` (frameRollSpan=65) is bigger than the thick ~53px edges on purpose** → the
  shadow is still fading when it hits the screen edge and **bleeds off** (no floating
  band on thick edges; on the 4px trim the overshoot keeps the near-edge part visible
  instead of collapsing to an invisible sliver).
- `peakFrac` = `frameRollEase` (2.0) = falloff exponent (skew toward the edge).

## Dead ends (don't repeat)
- **Normalised dual-SDF** (`dIn/(dIn+dOut)`, fades to exactly 0 at the outer edge):
  mathematically clean, but on the 4px right/bottom it fades over 4px → **invisible**.
  User: "shadow doesn't show at corners and bottom/right." Rejected.
- **Inset** (darkest at hole edge fading *inward* into the gap): user said it "looks
  perfect" but it's the **wrong direction** — they want it toward the outside.
- **Widening `framePadRight/Bottom` to 53px** (uniform border, gives the outset shadow
  room everywhere): user rejected — "added padding I didn't have before." Reverted.
- Earlier `dOut = min(px.x, W-x, …)` "distance to outer edge": creates a **diagonal
  seam at corners** ("corners are fucked up"). SDF-only avoids it.
- Window-tracking the shadow (bind holeRect to the focused toplevel geometry): the rice
  CAN read it (`Hyprland.toplevels[].lastIpcObject.at/size`), but with tiled windows
  there's no single content rect → fragile. Not pursued.

## Debugging technique that unstuck it
Early on the shadow "didn't show" and every change "looked the same" — I wrongly
thought the shader wasn't compositing. Proof it WAS: (1) force the frag to output
solid opaque red → whole screen red; (2) output red only where `d>0` → a clean
distance field (thin frame strip, clear content). The real bug was **I was cropping
screenshots at the wrong location** (assumed the content corner was at ~150,110; the
frame edge is elsewhere). Lesson: verify uniforms/geometry with a colour-debug frag
before assuming a render bug.

## Blur fix (frame must stay crisp)
The recess shadow raised the frame's per-pixel alpha (frameBg 0.50 + shadow → up to
~0.80) past the `ignorealpha 0.55` threshold, so Hyprland **frosted the shadow region**
(user: "it blurs the background behind it which I don't like"). Fix:
- `ContentFrame.qml` sets `WlrLayershell.namespace: "quickshell-frame"`.
- `hypr/conf.d/30-look.conf`: anchored the rules to `^quickshell$`
  (`layerrule = blur, ^quickshell$` + `ignorealpha 0.55, ^quickshell$`) so they match
  the bars/popups (exact "quickshell") but **not** the frame → frame never blurs,
  popups keep glass. (Hyprland layerrule namespace is a regex; bare "quickshell"
  matched "quickshell-frame" too.)

## Wallpaper-adaptive strength
`frameHiA = clamp(0.78 − 0.85·wallLum, 0.15, 0.60)`. `wallLum` from
`~/.cache/quickshell/surface.json` (set-wallpapers writes it; same palette IPC reload).
Current wallpaper luminance 0.69 → ~0.19 (user wanted it "way less pronounced" on light
wallpapers); dark wallpapers go up to 0.60.

## Build / reload cheatsheet
- Recompile shader: `qsb --glsl "300es,330,440" --hlsl 50 --msl 12 -o recess-shadow.frag.qsb recess-shadow.frag`
  (`qsb` at `/nix/store/...-qtshadertools-6.10.2/bin/qsb`).
- Restart QS: `pkill quickshell; setsid -f qs -p ~/.config/quickshell/rices/current/shell.qml`
- Reload Hyprland layerrules: `hyprctl reload` (safe, not a system rebuild).
- Capture for inspection: `grim -o eDP-1 out.png` then `magick … -crop … -filter point -resize`.

## Open / next
- Shadow saga is **done** (user: "yep that's it"). Only possible follow-up: fine-tune
  the `frameHiA` slope/floor if a future wallpaper feels too faint/heavy — one-number
  tweak.
- Still on branch `quickshell-frame-shape`; not merged to main.

See also: [2026-10-08 adaptive-theme recess-shadow] (the superseded ring-based roll +
the original "thin right/bottom clips" note this session fixed).
