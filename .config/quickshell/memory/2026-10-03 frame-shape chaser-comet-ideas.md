# 2026-10-03 — frame corner-gap fix + LED chaser / comet approach notes

Branch: `quickshell-frame-shape` (dotfiles). Frame fix committed `1d4ce98`.
These chaser/comet ideas are **captured only — NOT being implemented yet** (user's
call, 2026-10-03). Detailed feature specs already live in `ROADMAP.md`
("Chaser: light beam around the content frame border" + "...around the focused
window"); this note adds the *difficulty / approach* assessment from the session.

## Context that makes chasers easier now
`ContentFrame.qml`'s ring is now a single `Shape` / `ShapePath` (outer window rect
minus a rounded-rect hole, `OddEvenFill`). That means the exact frame perimeter —
including the rounded inner corners (`frameRadius`, clamped via `win._r`) — already
exists as a path. Any chaser can reuse / stroke that same path instead of
re-deriving perimeter geometry.

## Tier 1 — running light bead(s): EASY (~1–2 hrs, pure QML, no build tooling)
- Stroke a copy of the frame `ShapePath` with a **dashed line**
  (`strokeStyle: ShapePath.DashLine`, short bright dash + long gap), gradient stroke
  color, and animate **`dashOffset`** with `NumberAnimation { loops: Infinite }`.
- The bead travels the perimeter and **follows the rounded corners for free** (it's
  stroking the real path).
- Multiple chasers = more dashes in the pattern, or stacked stroked paths with phase
  offsets. Direction (CW/CCW) = sign of the `dashOffset` delta.
- GPU-cheap, declarative, no per-frame JS. Slots straight into the planned
  `EffectsState.qml` singleton (speed/count/color/direction as bound properties).

## Tier 2 — true "comet" (bright head → fading tail): MODERATE (~a day)
Uniform dashes can't fade along their length, so the comet look needs one of:
- **`ShaderEffect`** (ROADMAP's plan: parametric `t`∈[0,1] around perimeter, fragment
  shader draws the falloff). Most control, BUT **Qt6 `ShaderEffect` needs precompiled
  `.qsb` shaders** via the `qsb` tool → a shader-compile step added to the Nix build.
  That build friction is the real cost, not the math.
- **Animated gradient** (conical/linear) masked to the border stroke via `OpacityMask`
  — no build step, but making the gradient track the rounded corners cleanly is
  fiddlier than the shader.

## Recommendation when picking this up
Start with **Tier 1** (the dashed-stroke bead) — gives "LEDs circling the border,"
multiple chasers, per-chaser config, zero build tooling. Only move to Tier 2 if the
comet-tail falloff is specifically wanted. A standalone border chaser as its own
layer avoids the ROADMAP "big decision #1" offscreen-`layer.enabled` texture
constraint (that only bites if the chaser must compose with the music-visualizer
ripple).

## Wallpaper-driven theme — Phase 1 SHIPPED (2026-10-03)
Pipeline: `set-wallpapers` → `matugen image <current> --mode dark` →
`~/.cache/quickshell/colors.json` → `Appearance.qml` `FileView` (watchChanges) →
`_rgba(role, fallbackHex, alpha)` bindings → live recolour (no reload/rebuild).
- matugen config/template: `~/.config/matugen/{config.toml,templates/quickshell-colors.json}`.
- 8 tokens take HUE from matugen roles (surface/primary/secondary/tertiary/
  surface_container[_high]), keep original ALPHAS → identical look, wallpaper hues.
  Fallbacks = old purple literals (used if JSON missing/mid-write).
- **Decisions (user):** auto light/dark (eventually) + quickshell-only scope; but
  Phase 1 ships **dark-only** because light mode needs the ~145 hardcoded white
  foregrounds routed through central fg/bg tokens first (= Phase 2).
- matugen (3.0.0) added to nixos-config `hosts/common/default.nix` on branch
  `wallpaper-theme-matugen` (eval-verified). Dotfiles on `quickshell-frame-shape`.
- Verified live: FileView loaded colors.json (surface #282828, primary #fabd2f),
  pill borders/glow went gruvbox gold; clean reload logs (no warnings) after an
  `_r` NaN fix in ContentFrame (commit bff8ed9).
- **Deploy:** user runs `nrs` on BOTH laptops from branch `wallpaper-theme-matugen`
  (gets matugen), then `set-wallpapers` once to generate the real palette (the
  current `colors.json` is a hand-made gruvbox test file).

Related: [[2026-04-17 terminal-notifications]] · ROADMAP chaser + theme-switcher
sections (the frame fix unblocked the light-wallpaper theme switcher).
