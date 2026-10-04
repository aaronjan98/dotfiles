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
