# Appearance and Scaling

`config/Appearance.qml` is the main visual token file for the shell.

It is the closest thing this setup has to a design system.

## Wallpaper-driven palette (matugen, auto light/dark)

The colour tokens are **not static** — they track the wallpaper, and the whole
shell flips between a light and dark scheme depending on the wallpaper.

**Pipeline.** On every wallpaper change, `~/.config/hypr/scripts/set-wallpapers`:
1. measures the wallpaper's mean luminance with ImageMagick (`magick … -resize 1x1`)
   and picks `--mode light` (luminance > 0.5) or `--mode dark`;
2. runs `matugen image <current> --mode <mode>`, which renders a Material You
   palette to `~/.cache/quickshell/colors.json` (template + config in
   `~/.config/matugen/`);
3. calls `qs … ipc call palette reload` to tell the shell to re-read it.

**Why IPC, not a file watch.** `Appearance.qml` holds a `FileView` on the JSON, but
`watchChanges` does **not** fire for matugen's writes — matugen writes atomically
(temp file + rename), which replaces the inode and defeats inotify. So the reload
is triggered explicitly over IPC (the `IpcHandler` with `target: "palette"` in
`Appearance.qml`), which calls `_paletteFile.reload()`. `onLoaded` then reparses
into the `palette` property and every colour binding recomputes — live, no reload.

**Mode detection in QML.** There's no separate flag: `fg` = matugen's `on_surface`
(light in dark mode, dark in light mode), and `isDark` is derived from `fg`'s
luminance. Panel alphas are higher in light mode (light panels need more opacity to
register over a light wallpaper) — see the `isDark ? … : …` ternaries.

**Tokens.** Hues come from matugen roles (`surface`, `surface_container_high`,
`surface_container_highest`, `primary`, `secondary`, `tertiary`, `on_surface`); the
new `fg` / `fgDim` carry text/icon colour (the 53 former hardcoded whites now bind
to `fg`). Every role has a **fallback** (the original purple dark theme) used if the
JSON is missing or caught mid-write, so the shell always has valid colours.

To extend the recolour to other apps (kitty/GTK), add `[templates.*]` blocks to the
matugen config — nothing in the shell changes.

## Content-frame recess shadow (SDF shader)

The soft shadow that makes the content read as recessed into the frame is drawn by a
single `ShaderEffect` in `components/frame/ContentFrame.qml`, not by stacked rings.
(It replaced an earlier glow-ring `Repeater` "roll" that could only ever render as a
band/clip.) The shader is a signed-distance-field gradient:

- **Files**: `components/frame/recess-shadow.frag` + `.vert`, compiled to `.frag.qsb`
  / `.vert.qsb`. Qt6 loads the `.qsb`, so **both `.qsb` files must be committed** —
  there is no build step. A matching vertex shader is required (the default
  `ShaderEffect` vertex shader did not link `qt_TexCoord0` on the OpenGL backend), and
  its UBO must be **byte-identical** to the fragment's. Recompile after editing:
  ```bash
  qsb --glsl "300es,330,440" --hlsl 50 --msl 12 -o recess-shadow.frag.qsb recess-shadow.frag
  ```
  (`qsb` ships with qtshadertools; find it under its `/nix/store/...-qtshadertools-*/bin/`.)
- **Shape**: `sdRoundedBox` distance to the content hole; shadow is **darkest right at
  the content-frame edge** and fades **outward** into the frame fill. The span
  (`frameRollSpan`) is deliberately sized **larger than the thick frame edges**, so the
  shadow is still fading when it reaches the screen edge and **bleeds off** instead of
  ending inside the frame as a floating band.

**Frame geometry reality (why bleed-off matters).** The frame fill is thick on the
top/left (~53px — the bars reserve that via `topHFramework`/`leftW`) but a thin trim on
the right/bottom (`framePadRight`/`framePadBottom` = `s(2)` ≈ 4px). A fade that reaches
0 *within* the fill therefore collapses into an invisible sliver on the thin edges; the
oversized span lets the near-edge part stay visible there (bleeds off the screen). Note
also that a tiled/cell-quantised window floats *inside* the hole with gaps, so the
shadow hugs the **frame (hole) edge**, not the window itself.

**Tokens** (in `Appearance.qml`):
- `frameHiA` — peak shadow alpha, **wallpaper-adaptive** (`0.78 − 0.85·wallLum`, clamped
  0.15–0.60): faint on light wallpapers (a dark recess reads stark over a pale frame),
  strong on dark ones where it would otherwise vanish. `wallLum` comes from
  `~/.cache/quickshell/surface.json` (written by set-wallpapers, reloaded over the same
  palette IPC).
- `frameRollSpan` — outward reach in px (the oversized bleed-off span).
- `frameRollEase` — falloff exponent (higher = mass skewed harder to the content edge).
- `frameRollColor` / `frameRollTail` — legacy; the shader hardcodes black and ignores
  the tail term.

**Blur / namespace.** The content frame is a semi-transparent tint over a **crisp**
(un-frosted) wallpaper. It sets `WlrLayershell.namespace: "quickshell-frame"`, and the
Hyprland blur rules in `hypr/conf.d/30-look.conf` are anchored to `^quickshell$` so they
match the bars/popups but **not** the frame. Without this, the recess shadow pushes the
frame's alpha past the `ignorealpha` threshold and the whole frame gets frosted.

## What belongs in `Appearance.qml`

Broadly, this file should own:

- bar dimensions
- frame geometry
- radii
- border widths
- spacing and padding values that are reused in multiple places
- core colors
- popup and pill styling tokens
- font family choices for icon fonts

## Confirmed token categories

The file has included tokens such as:

- global scale ideas like `uiScale`
- bar thickness
  - `topH`
  - `leftW`
- frame geometry
  - `framePadRight`
  - `framePadBottom`
  - `frameRadius`
  - `border`
  - `borderInset`
- palette values
  - `frameBg`
  - `borderCol`
  - `glow1`
  - `glow2`
  - `glow3`
- bubbles
  - `bubbleBg`
  - `bubbleBorderW`
  - `bubblePad`
  - `bubbleRadius`
  - `nixBubbleSize`
  - `nixIconPad`
- popups
  - `popupBg`
  - `popupOverlayA`
  - `popupPad`
  - `popupRowGap`
- pills
  - `pillPadX`
  - `pillPadY`
  - `pillRadius`
  - `pillFont`
  - `pillBorderW`
  - `pillBorderCol`
- icon font
  - `iconFont`

## Why centralization matters

If sizes are hardcoded all over widget files, then:

- scaling becomes painful
- changing one visual concept requires editing many files
- it becomes unclear which numbers are intentional design tokens versus ad hoc local tweaks

When the tokens are centralized:

- changing the shell's density is easier
- changing pill shape is safer
- popup styling stays consistent
- workspace islands inherit design changes more predictably

## Current scaling direction

A scaling pass was attempted by introducing a global `uiScale` and then teaching widgets to read appearance tokens.

That direction is architecturally correct, but the migration must be done carefully:

- every new token used by a widget must actually exist in `Appearance.qml`
- partial migration leads to `undefined` property assignments in QML
- popups and icons can disappear or break if a file expects tokens that are not yet defined

## Practical guidance for safe scaling

The safe approach is:

- add tokens to `Appearance.qml` first
- then update a small number of widgets to consume them
- verify there are no `undefined` warnings
- continue file by file

This is better than:

- editing many widgets at once
- introducing new token names without adding them centrally

## Current pill sizing insight

The easiest way to tighten the side pills is through:

- `pillPadX`
  - reduces left/right interior space
- `pillPadY`
  - reduces top/bottom interior space

Because `Pill.qml` computes its height as content height plus `padY * 2`, decreasing `pillPadY` is the cleanest way to remove vertical bulk.

## What should stay local vs global

### Good candidates for global tokens

- repeated spacing values like `6`, `8`, `10`, `12`
- repeated row heights like `28`, `34`
- shared icon sizes
- popup widths and radii
- divider dimensions

### Fine to keep local for now

- one-off experimental offsets during active prototyping
- animation logic that is unique to one widget
- values that are genuinely specific to a single UI affordance

## Recommended long-term direction

A strong long-term cleanup would look like this:

- `Appearance.qml` defines reusable spacing tokens and common geometry tokens
- widgets consume those tokens consistently
- magic numbers are gradually eliminated from:
  - `TopBar.qml`
  - `LeftBar.qml`
  - popup widgets
  - icon widgets
- the shell gains a robust, centralized scale model without brittle migrations

## Warning signs during theme/scaling work

If you see warnings like:

- `Unable to assign [undefined] to int`
- `Unable to assign [undefined] to double`
- `Unable to assign [undefined] to QColor`

that almost always means:

- a widget is referencing a token that `Appearance.qml` does not define
- or the token exists under a different name than the widget expects

The fix is almost never to fight the widget directly.
The fix is usually to align the widget and `Appearance.qml` on a shared token vocabulary.
