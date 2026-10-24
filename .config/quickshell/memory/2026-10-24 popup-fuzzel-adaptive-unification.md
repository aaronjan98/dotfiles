# 2026-10-24 — popups/fuzzel unified on one wallpaper-adaptive surface (12:55 PDT)

Branch: `quickshell-frame-shape` (dotfiles). Continuation of the frame/shadow work
([[2026-10-23 recess-shadow-sdf]]). This session was a wallpaper-adaptivity pass:
started from "shadow/tint a bit much", ended with every popup + the fuzzel launcher
sharing ONE adaptive surface token. Nothing pushed/merged to main.

## What was worked on (in order the user asked)
1. **Softer frame** — `frameBg` 0.50→0.42; recess-shadow curve lowered (`frameHiA`
   intercept 0.78→0.70, clamp 0.15–0.60 → 0.12–0.52). Still dark-darker/light-lighter.
2. **Grayscale tint was blue** — matugen can't seed a hue from a B&W wallpaper, so its
   `source_color` falls back to the built-in **#4285f4 (Google blue)**; `frameBg` binds
   to `source`, so the frame went blue on any grayscale wallpaper. Fix below.
3. **Islands unreadable on busy wallpapers** — the old `bubbleBg` faded to 0 as wallpaper
   *intensity* rose (= bright AND busy), the opposite of what a busy wallpaper needs. Fix below.
4. **Islands too opaque / "pure white"** — tone + alpha fix below.
5. **kitty green + hard to read** — NOT our bug; explained, left alone (see below).
6. **All popups mismatched** — wifi/bt/brightness hardcoded dark purple; popups didn't
   match each other or the frame. Unified them + fuzzel. Then: "a tad darker than the
   dominant", and "fuzzel bg doesn't match". Fixes below.

## Key mechanisms added (all in `config/Appearance.qml`)
- **`_neutralize(c)`** — on a grayscale wallpaper (measured `wallSat` < ~0.05, tight band
  0.02–0.07 via `_tintKill`), blend a wallpaper-seeded colour toward a grey **at the
  wallpaper's own brightness** (`wallLum`), NOT a fixed mid-grey — so a white-dominant B&W
  wallpaper → white frame, a dark one → dark frame. Colourful wallpapers: `_tintKill`=0, no-op.
  Applied to `frameBg` + `borderCol` + `glow1/2/3`.
- **`_darken(c, f)`** — relative RGB scale (×f). Used ×0.80 on `popupBg`. Relative on purpose:
  an absolute lightness set (matugen's `set_lightness`) would *lighten* a dark-dominant seed.
- **`popupBg = _darken(_neutralize(_rgba("source", …, 0.64)), 0.80)`** — the ONE popup surface.
  Same `source` tint as `frameBg` (so popups match the frame), **0.64** alpha so the tint wins
  over the frosted backdrop (at 0.50 a toast in a red wallpaper-corner went red, not frame-
  coloured — backdrop was dominating), then ×0.80 so popups sit a touch behind the frame.
- **Island fill `_bubbleA`** — keyed to **busyness** (`wallStdev` from surface.json), not
  intensity: smooth wallpaper (stddev ≤0.14) → ~0.14 airy; busy (≥0.24) → ~0.48, above the
  frost cutoff so Hyprland frosts a clean chip. Tone = `surface_container_highest` (light grey
  glass, matching popups), NOT `surface` (near-white → solid white block at high alpha).

## Popup widgets — point them ALL at `popupBg`
- `WifiPopup` / `BluetoothPopup` / `BrightnessPopup`: replaced hardcoded
  `Qt.rgba(35/255,26/255,60/255,0.97)` (= #231a3c purple) + lavender border with
  `C.Appearance.popupBg` + `C.Appearance.borderCol`. (In light mode the purple bg + adaptive
  dark `fg` text = dark-on-dark, unreadable — that was the real bug.)
- `PowerPopup`: already adaptive; **removed** its black "dark glaze" overlay (muddied the
  light-mode panel and made it differ from the notif centre).
- `NotificationCenter`: panelBg was `bubbleBg`-rgb @ 0.78 (its own recipe) → `popupBg`; border
  `fgA(0.10)` → `borderCol`.
- `NotificationToast`: bg `bubbleBg @ 0.82` → `popupBg`; radius `bubbleRadius` (s17≈30px, "too
  round") → `frameRadius` (s7≈12px, matches the notif centre).

## fuzzel — wallpaper-adaptive (was static purple in fuzzel.ini)
fuzzel is a separate app; its layer namespace is **`launcher`** (verified via `hyprctl layers`).
- `~/.config/matugen/templates/fuzzel-colors` (new) + `[templates.fuzzel]` in matugen config →
  renders text/prompt/selection/border/etc. from the palette to `~/.cache/quickshell/fuzzel-colors`.
- **Background is NOT in the template** — matugen has no relative-darken filter, so
  `set-wallpapers` appends `--background-color=<source ×0.80>a3` (a3≈0.64) after matugen, so
  fuzzel's bg exactly matches `popupBg` (same source, same 0.80, same 0.64).
- `~/.config/hypr/scripts/fz` reads the cache file (`grep '^--'`, skips the comment header) and
  passes the flags BEFORE `"$@"` so callers still override. Missing file → falls back to
  fuzzel.ini's static purple.
- `30-look.conf`: `layerrule = blur/ignorealpha 0.30, ^launcher$` so fuzzel frosts like the shell.
- Pre-existing harmless warning: fuzzel.ini line 29 `fuzzy=yes` is deprecated (`match-mode=fuzzy`
  now) — left alone, user declined.

## Hyprland blur cutoff
`30-look.conf`: `ignorealpha 0.55 → 0.30` for `^quickshell$` (and `^launcher$`). Needed so the
thinner island/popup glass (~0.48–0.64) still frosts. The PowerPopup scrim is **0.28**, just
UNDER 0.30, so it stays unfrosted — don't raise island/scrim alphas past each other's band.

## set-wallpapers additions
Measures **saturation** (`magick -resize 64x64 -colorspace HSL -channel g -separate '%[fx:mean]'`)
and writes it to surface.json (feeds `_neutralize`); appends fuzzel's darkened-source bg (feeds
fuzzel match). Both best-effort. surface.json now: intensity, luminance, stddev, saturation, mode.

## kitty green (NOT our change)
On a light wallpaper kitty uses `colors-light.conf` which hardcodes `background #dbe6d2` (pale
green) at `background_opacity 0.5`; over a busy wallpaper the half-wallpaper backdrop drags
contrast with the dark `#37322c` fg. kitty is static (not matugen-driven). Offered to bump the
opacity / make it adaptive / retint — user said leave it.

## Debug/verify notes
- Can't screenshot wifi/power popups: **no mouse-click injector** (`ydotool`/`dotool` absent,
  only `wtype` = keyboard). Verified those via `qmllint` + reasoning + the notif-centre reference.
- fuzzel opens on the **focused** monitor — it landed on DP-1 (ultrawide, scale 1.6) mid-session;
  `grim -o eDP-1` won't catch it there, and DP-1's 1.6× scaling offsets layer ge/crop coords.
- The user **changed wallpapers several times** mid-session (grayscale cat → green platform →
  salmon car), which is why shots flip green/red — the adaptive path handled each correctly.

## Open / next
- Big uncommitted→committed batch this session (4 commits). Still on `quickshell-frame-shape`,
  not merged to main.
- Tunable one-liners if a wallpaper feels off: `popupBg` alpha (0.64) / darken (0.80); island
  `_bubbleA` ends (0.14/0.48) + crossover; `frameHiA` slope/floor; neutralize band (0.02–0.07).
- fuzzel.ini `fuzzy=yes` deprecation warning still there (user declined the fix).

See also: [[2026-10-23 recess-shadow-sdf]] (frame geometry, SDF shader, blur/namespace split).
