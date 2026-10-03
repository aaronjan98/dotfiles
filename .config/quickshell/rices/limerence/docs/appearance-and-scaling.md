# Appearance and Scaling

`config/Appearance.qml` is the main visual token file for the shell.

It is the closest thing this setup has to a design system.

## Wallpaper-driven palette (matugen, Phase 1)

The colour tokens are **not static** anymore — their hues track the wallpaper.

- On every wallpaper change, `~/.config/hypr/scripts/set-wallpapers` runs
  `matugen image <current> --mode dark`, which renders a Material You palette to
  `~/.cache/quickshell/colors.json` (template + config in `~/.config/matugen/`).
- `Appearance.qml` holds a `FileView` (`Quickshell.Io`) on that JSON with
  `watchChanges: true`. On load it parses the file into the `palette` property;
  the colour tokens are bindings through the `_rgba(role, fallbackHex, alpha)`
  helper, so reassigning `palette` **recolours the shell live** — no reload.
- Only the **hue** comes from matugen (roles: `surface`, `primary`, `secondary`,
  `tertiary`, `surface_container`, `surface_container_high`). Each token keeps its
  **original alpha** (`frameBg` 0.55, glow 0.27/0.12/0.08, …), so the look is
  unchanged and only the colours move.
- Every role has a **fallback** (the original hand-picked purple, as a hex literal)
  used when the JSON is missing (first run before matugen) or caught mid-write, so
  the shell always has valid colours.

This is **Phase 1: dark scheme only.** True auto light/dark is Phase 2 and is
blocked on routing the ~145 hardcoded white foregrounds through central `fg`/`bg`
tokens (see `docs/ROADMAP.md` in nixos-config → "Live runtime theme switcher").
To add more apps (kitty/GTK), add `[templates.*]` blocks to the matugen config;
nothing in the shell changes.

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
