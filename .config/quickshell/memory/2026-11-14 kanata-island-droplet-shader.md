# 2026-11-14 — Kanata mode island: word labels + glass-pill droplet shader

Continuation of the kanata mode island work (Phase 1 built and committed in an
earlier session — see `project-memory/kanata-island.md` and the quickshell
ROADMAP entry). This session was almost entirely visual/interaction iteration
on `components/widgets/KanataIsland.qml`, done live against the user's actual
running bar, with a lot of back-and-forth tuning based on direct feedback.

## What was worked on

1. **Mode labels: single letters → words spelled downward.** `KanataCtl.qml`'s
   `modes` table now carries `word: "Norm"/"Cap"/"Maj"` instead of a single
   `letter`. `KanataIsland.qml` restructured so each mode is a "block" of
   stacked single-character rows. Letters *within* a word have zero gap
   (`letterGap`); gap only appears *between* words (`gap`/`modeCellGap`).
   First letter of each word sits in a full-height row, the rest in a shorter
   `lowerCellHeight` (`cell*0.78`) row — otherwise lowercase letters read as
   evenly/loosely spaced even with zero inter-letter gap, because the ROWS
   themselves were still uniform height regardless of glyph ink size.

2. **The droplet became a real GLSL shader.** `kanata-droplet.frag`/`.vert`,
   compiled to `.qsb` the same way `components/frame/recess-shadow.frag` is
   (see that pair + `docs/appearance-and-scaling.md` for the `qsb` invocation).
   Two reasons it had to be a shader, not stacked QML Rectangles: (a)
   squash-and-stretch elasticity needs a true shape with independently
   animatable width/height; (b) a real per-pixel-blurred reflection needs
   gaussian falloffs plain QML can't do. Confirmed this build has NONE of
   `QtQuick.Effects`, `Qt5Compat.GraphicalEffects`, `QtQuick.Shapes` — so no
   blur/radial-gradient/arc primitive exists at the QML level either way.

3. **Ellipse → capsule/pill SDF.** The first shader drew a plain ellipse
   (`length(d/radius)`). Rejected: every point on an ellipse depends on BOTH
   radii, so it can't keep flat sides still while growing in only one
   direction, and its continuously-curved silhouette reads as "blurry" even
   with crisp AA. Switched to the exact `sdRoundedBox` SDF already used in
   `recess-shadow.frag`, with `b = (radiusX, radiusY)` and `r =
   min(radiusX, radiusY)` — this degenerates into a true capsule: flat sides,
   semicircular caps.

4. **Physics rewrite: direction-only stretch.** First attempt (a single
   `stretch` scalar pulsing radiusY up then easing down, with radiusX
   compensated by `1/sqrt(stretch)`) was wrong on two axes: it stretched
   horizontally too (fixed by making radiusX a true constant), AND it grew
   symmetrically "up and down" from a fixed center regardless of travel
   direction (the real bug the user kept flagging as "physics still wrong").
   Final design: `topEdge`/`bottomEdge` are TWO independently-animated
   properties, each driven by its own `NumberAnimation`
   (`topEdgeAnim`/`bottomEdgeAnim`). On every mode change,
   `root.onActiveIndexChanged` figures out travel direction and makes the
   LEADING edge snap fast (~110ms) while the TRAILING edge eases in slowly
   (~420ms) — that lag IS the elongation, and it only ever happens on the
   trailing side. radiusX never varies at all (motion here is always
   vertical, one column of modes).

5. **Border/reflection: many rounds of "make it look like glass, not a
   glow".** Final shader structure, in dependency order:
   - `rimOffset` (2.0px): the border sits pulled IN from the true geometric
     edge, not straddling it.
   - `core`'s own fade-out is anchored to that SAME `distRim` line, not the
     true boundary — an earlier version anchored core to `dist==0` instead,
     which left a low-opacity halo filling the gap between the crisp border
     and the real edge ("glow extends past the border").
   - `rim`: a band at `rimAA=0.6` transition width (0.15 was tried and was
     TOO tight — aliases/stairsteps on the curved caps; a flat line can be
     near-hard-step, a curve can't). `rimAlpha=1.0`, color mixed only 0.2
     toward white (a 0.65 mix read as "pale highlight", not "solid border").
   - `crescent` (reflection): centered at the SAME `distRim` as the rim (so
     it "hugs" the border instead of forming its own separate ring further
     out), masked to the INNER side only via `crescentMask` so its gaussian
     tail can never bleed past the rim's own crisp outer edge, narrow
     (`capR*0.22`), low alpha (`0.14`).

6. **Sizing/nesting, several corrections.** The droplet's resting
   width/height are NOT independent magic numbers — they're derived from the
   chassis's own padding so they're geometrically guaranteed to stay nested:
   - `baseRadiusX = pill.width/2 - widthInset` (currently `widthInset = 0`,
     i.e. flush with the chassis's own half-width — a `+hMargin` outward
     push and a `-widthInset` inward pull were both tried; user wants flush).
   - `vMargin` (how far past the first/last letter the capsule reaches) —
     **currently `vMargin = padV` exactly** (zero formula-level gap). A
     `*0.85` ratio was tried first and measured wrong: `padV` is a small
     integer (9px at current tokens), so a ratio's rounding barely moves —
     not actually tunable that way. Pixel-sampled a real screenshot (PIL,
     via `nix shell --impure --expr 'python3.withPackages(...)'` since
     `nix shell nixpkgs#python3Packages.pillow --command python3` does NOT
     expose a `python3` binary on PATH -- the withPackages expr form does)
     to confirm the gap before/after.
   - **Chassis padding had to be split into two tokens**: `modeCellPad`
     (horizontal, governs island WIDTH) and `modeCellPadV` (vertical only).
     Originally one shared `pad` governed both; bumping it for "more room at
     top/bottom" also silently widened the whole island, which the user did
     not want and caught immediately.

7. **Colors**: moved from matugen-role-derived (`_c("primary",...)`) to FIXED
   hex (`#2ecc71` green / `#3498db` blue / `#e74c3c` red) for
   modeColDefault/Caps/Maj -- these are a semantic traffic-light identity, and
   matugen's primary/secondary/tertiary are whatever hues the CURRENT
   wallpaper happens to generate, which would silently break that identity on
   a wallpaper change.

8. **Removed `font.bold` on the active letter** (last request, unverified
   visually — no screenshot taken after this specific change, see Open
   below).

9. **Dropped a stale `font.bold: wordBlock.active`** and fixed a text-
   centering bug along the way: `anchors.centerIn` on a `Text` centers each
   glyph's own tightly-cropped ink bounds, which differs per letter shape
   (confirmed: "N" lined up with the droplet, "C"/"M" sat visibly right of
   it). Fixed with `anchors.fill` + `Text.AlignHCenter`/`AlignVCenter`
   against the fixed cell instead, which uses the font's real layout metrics
   — the same reference frame for every character.

## Key insights / debugging techniques that worked

- **Screenshot verification loop**: `grim` → `magick convert -crop ... -resize
  N% -filter point` (nearest-neighbor, critical — a smooth resize filter
  would hide exactly the jaggies/softness being evaluated) → `Read` the PNG.
  Caught real bugs this way that pure code review missed (the ink-bounds
  text-centering bug; the Maj-specific gap).
- **`grim` hung/timed out intermittently** this session (3 real tool
  failures in a row at one point) with no obvious cause — not a stale
  process (nothing left running), not reproducible on retry-after-wait.
  Recovered on its own after a `pkill quickshell` + relaunch cycle. If it
  recurs: don't loop retrying blindly past ~3 attempts: `pkill`/kill the
  hung PID and move on, or ask the user to check manually.
- **Pixel-sampling a screenshot with PIL beat eyeballing an upscaled crop**
  for the Maj-gap bug specifically — the visual "is this gap bigger" judgment
  from a 600%-nearest-neighbor PNG crop was not reliable enough on its own;
  exact row-by-row color sampling (find first/last row matching the
  chassis-border color vs the capsule-fill color at a few x columns) gave an
  actual number to reason from.
- **`nix shell nixpkgs#python3Packages.pillow --command python3` does NOT
  put a `python3` binary on PATH** (confirmed, reproducible) — contrary to
  the general `tool-commands.md` guidance that a package derivation exposes
  a usable python3. Use the `--impure --expr
  'python3.withPackages(ps: with ps; [pillow])'` fallback form instead for
  pillow specifically.
- **A ratio of a small integer barely moves when rounded** — `vMargin =
  round(padV * 0.85)` at `padV=9` only has ~11 distinct achievable values
  across the whole 0..1 ratio range, so "nudge the ratio a bit" requests
  from the user sometimes produced literally the same output value. Prefer
  exact equality or a fixed-offset subtraction over a ratio when the base
  value is a small integer and fine control matters.
- **Restart command that works reliably in this sandboxed session**:
  `pkill quickshell 2>/dev/null; sleep 1; setsid -f qs -p
  ~/.config/quickshell/rices/current/shell.qml`. `nohup ... & disown` was
  flaky (recurring "Exit code 144" artifacts, sometimes losing the launched
  process) — `setsid -f` (from the project's own
  `memory/2026-10-23 recess-shadow-sdf.md` cheatsheet) did not have this
  problem.
- **`qsb` invocation**: `nix shell nixpkgs#qt6.qtshadertools --command qsb
  --glsl "300es,330,440" --hlsl 50 --msl 12 -o out.frag.qsb in.frag` — same
  as documented for `recess-shadow.frag`. This DOES expose `qsb` on PATH
  fine (unlike the pillow case above).

## Decisions

- Fixed semantic colors (green/blue/red) over wallpaper-adaptive matugen
  roles, for THIS island specifically (traffic-light identity matters more
  than theme consistency here).
- Capsule shape over ellipse, for shape-consistency with the direction-only
  stretch physics and for crispness.
- Horizontal and vertical chassis padding must be separate tokens
  (`modeCellPad` vs `modeCellPadV`) — never reuse one `pad` for both again on
  this widget.
- `vMargin`/`widthInset` as values *derived from* the chassis padding
  (currently exact-equal / zero respectively), not independent constants —
  keeps the capsule geometrically guaranteed-nested by construction.

## Open questions / next steps

- **Not yet visually confirmed**: the `font.bold` removal (last change made,
  no screenshot taken after it specifically — low risk, but unverified).
- The reflection ("crescent") tuning has been through ~5 rounds
  (opacity/width/position all moved multiple times) chasing "looks like
  glass, not a glow" — current state (`rimOffset`-centered, masked to inner
  side, `capR*0.22` width, `0.14` alpha) is the most recent, but this was the
  single hardest thing to get right by description alone; expect it may need
  another pass once seen in different lighting/wallpapers.
- Phase 2 (language sub-island, accent engine) is still not started — see
  `project-memory/kanata-island.md` for that design, which predates this
  session's work and is unaffected by it.
- Two commits this session: an earlier WIP for Phase 1 (TCP server + daemon +
  basic mode pill), and this session's WIP for the word-label + shader
  redesign (about to be committed).
