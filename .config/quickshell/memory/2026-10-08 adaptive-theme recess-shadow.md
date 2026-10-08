# 2026-10-08 — wallpaper-adaptive opacity/blur + content-frame recess shadow + light-mode legibility

Branch: `quickshell-frame-shape` (dotfiles). Continuation of the 2026-10-03 frame
work. Commits this session: `83c1e4c` → `786dfdf` (14 commits, nothing pushed /
merged to main). set-wallpapers lives under `~/.config/hypr/` (also dotfiles).

## What was worked on

### 1. Content-frame recess shadow (the inner "roll")
`components/frame/ContentFrame.qml` — the inner edge treatment became a **dark** soft
shadow (`frameRollColor: "#000000"`) instead of a white highlight, so the Hyprland
window reads as **raised/onset** and the frame/menu as **inset** (user's framing: the
glow lines act as a lip around the window). Shape of the roll is a two-term ramp:
- `frameRollSpan` (50px) — how far it stretches from the content lip into the frame.
- `frameRollEase` (steep term) + `frameRollTail` (gentle term) — blended in the
  Repeater so the shadow concentrates hard at the inner lip but keeps a long gradual
  faint tail outward. (Committed `83c1e4c`.)
- The crisp inner outline ring is now `visible: false` (the roll + glows carry the edge).
- NOTE the roll draws OUTWARD into the frame via negative margins; on the thin
  right/bottom frame edges (~4px) a wide span clips — only the thick top/left show the
  full tail. Not fixed (would need widening framePadRight/Bottom).

### 2. External monitor (DP-1) alignment fixes
- Top-bar islands sat ~5px high → `TopBar.qml` `islandYOffset` set to `0` (`abf8684`).
- Nix corner (`CornerPatch.qml`) had the same negative offset → `0` on external (`29f49e1`).
- Nix icon enlarged **external-only** (factor 1.0 vs laptop 0.92), `clip: false` on the
  bubble (clip was slicing the snowflake's right arm — looked cramped), small rightward
  `horizontalCenterOffset` for even L/R padding (`188c2a0`, `849ae18`, `bcadcd1`).

### 3. Nix logo behaviours (`CornerPatch.qml`)
- **Hover-spin**: slow clockwise, `NumberAnimation` on `rotation` (NOT `RotationAnimator`
  — NumberAnimation updates on the main thread so stopping **freezes in place**; each
  hover resumes from the frozen angle, from→to spans exactly 360° so the infinite loop
  wraps seamlessly).
- **Per-scheme logo**: rainbow variant in light mode, colours in dark (`isDark`) —
  `cc915a0`. (Two SVGs exist: `assets/icons/nix-snowflake/nix-snowflake-{colours,rainbow}.svg`.)
- **Faked outline** for legibility on bright wallpapers: 8 black copies of the SVG
  offset 1px (MultiEffect `colorization: 1`), grouped with the colour logo in `nixGroup`
  so the hover-spin rotates both. (A soft `MultiEffect` shadow was tried first but spread
  past the corner window and clipped at the bar; the crisp outline doesn't spread.) `c75aa99`.

### 4. Light-mode legibility
- Battery glyph (`BatteryIcon.qml`): thin black outline via `Text.style: Text.Outline` +
  `styleColor` (light mode only). Works for every battery glyph variant, no asset needed.
- `bb76fd5` bundled the solid-panel + icon-outline first pass (later superseded by the flip).

### 5. Wallpaper-adaptive panel opacity + blur (the headline)
Pipeline: `set-wallpapers` measures mean luminance (`%[fx:...]`, already did) **and**
busyness (`%[fx:standard_deviation]`), computes `intensity = 0.75*lum + 1.5*sdev`
(0..1), writes `~/.cache/quickshell/surface.json` `{intensity, luminance, stddev, mode}`,
drives Hyprland blur via `hyprctl keyword decoration:blur:{size,passes}`, and the
existing `palette reload` IPC now re-reads surface.json too (so it updates live).
`Appearance.qml` reads `intensity` → `_byWall(darkEnd, lightEnd)` lerps the three panel
alphas across the 0.30..0.78 intensity band. Commits `641f468`, `271f4b0`, `786dfdf`.

## Key decisions / insights
- **Opacity direction FLIPPED** mid-session. First built "brighter/busier → MORE
  opaque" (`641f468`). User then said the result was "too white": once blur frosts the
  wallpaper, a bright wallpaper is **already** a light backdrop, so a solid panel on top
  just reads as a white block. Flipped to **brighter/busier → MORE transparent**
  (`271f4b0`): let the frosted wallpaper be the backdrop. Landed on bubble ~0.20 / frame
  ~0.16 / popup ~0.74 at the light end (near-pure frosted glass, a *hint* of tint so dark
  text stays legible); dark-wallpaper end stays more opaque (0.40/0.45/0.82). This matches
  the user's original instinct ("lighter opacity on light + more blur").
- **Icon legibility comes from the OUTLINES, not panel opacity** — that's what lets the
  panels go so transparent.
- **Blur is GLOBAL in Hyprland** (`decoration:blur:size/passes`) — no per-layer strength.
  Driving it per-wallpaper changes blur for ALL windows. `hyprctl keyword` is runtime-only
  (a full hypr reload resets to 30-look.conf's size=4/passes=1; next wallpaper reapplies).
  User OK'd global. Settled on size range 4..6, **passes pinned to 1** (2 passes read too
  muddy on bright wallpapers; size alone modulates).
- **Frame recess shadow keyed to LUMINANCE, not intensity** (`786dfdf`). It had been on
  the combined intensity, but busyness *raises* intensity → a busy wallpaper wrongly made
  the shadow *subtler*. For a black shadow what matters is how pale the light frame is =
  brightness alone. `frameHiA = clamp(0.08, 0.28, 0.32 - 0.34*wallLum)`: ~0.10 over white,
  ~0.14 at the current wallpaper, ~0.28 over dark/busy (lower-luminance) wallpapers.

## Calibration reference (current wallpaper)
`~/Pictures/Wallpapers/nature-landscape-horizon/c4-spring-sakura-sky.jpg`:
lum ≈ 0.53, sdev ≈ 0.26 → intensity ≈ 0.78 (the `_byWall` light-end ceiling), frameHiA ≈ 0.14.

## Operational gotchas (for next session)
- **Quickshell auto-reload did NOT pick up `.qml` edits this whole session.** Had to
  restart the process to apply changes: `setsid -f /run/current-system/sw/bin/qs -p
  ~/.config/quickshell/rices/current/shell.qml`. Worth investigating separately.
- **Killing quickshell**: its process `comm` is `.quickshell-wra` (Nix wrapper), so
  `pkill -x quickshell` misses it; use `pkill quickshell` (substring). Do NOT use
  `pkill -f "quickshell -p …"` in a command that also *contains* that string (e.g. a grep)
  — it matches your own shell and kills it (exit 144).
- **Visual verification**: `grim -o DP-1 out.png` then `magick` crop / `-resize 1x1! txt:-`
  or `Nx1! txt:-` for pixel-row/column brightness profiles. grim captures DP-1 at physical
  3440×1440 (logical ×1.6).

## Open questions / next steps
- Dark/busy-wallpaper end of BOTH the adaptive opacity and the recess shadow is
  **calibrated, not visually confirmed** (only the current light wallpaper was on screen).
  Verify on a dark and a busy wallpaper; tune `_byWall` dark anchors + the `0.32 - 0.34*
  wallLum` curve if needed.
- Adaptive blur is global — if the heavier blur on normal windows bothers the user, dial
  the `bsize` range down in set-wallpapers.
- Still deferred (user's call): the **LED chaser / comet** border shader — see
  `2026-10-03 frame-shape chaser-comet-ideas.md` and ROADMAP.
- Branch `quickshell-frame-shape` is unpushed and unmerged to main.
