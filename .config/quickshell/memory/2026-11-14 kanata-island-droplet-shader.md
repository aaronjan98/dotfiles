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

---

## Continuation (same day) — static colour backdrop, lens experiment (reverted), and a real animation bug

Picked back up right after the commit mentioned above. User kept reporting
"the bubble flickers/blinks/changes colour before moving" through several
rounds of fixes that each turned out to be real but NOT the actual cause.
The eventual real bug was a classic QML footgun that had already bitten this
same file once earlier without being generalized from.

### What was worked on

1. **Continuous colour backdrop became a second shader**
   (`kanata-trackbg.frag`/`.vert`). First tried as plain QML: a
   `Rectangle{clip:true; radius:...}` wrapping a `Column` of flat per-word
   `Rectangle`s plus small 2-stop `Gradient` rectangles at the seams. Looked
   right in a quick look, but was actually broken two ways once
   screenshotted at real pixel size: **`clip:true` does NOT mask children to
   the rectangle's own rounded `radius` in this Qt build** — the top/bottom
   caps rendered as empty black domes instead of filled colour — and the
   colour blend between words was a literal `Gradient` painted over only
   `gap`-many real device pixels (a small integer, ~10-15px), too few to
   read as a fade rather than a hard seam. Replaced with a hand SDF mask
   (same `sdRoundedBox` technique as `kanata-droplet.frag`/
   `recess-shadow.frag`): the mask is exact regardless of clip support, and
   the 3-colour blend is a `smoothstep` computed at full fragment precision
   over a tunable `transitionWidth` (`gap * 1.6`), independent of layout.

2. **Lens experiment, tried and fully reverted.** To make "the bubble picks
   up colour from the island instead of carrying its own", tried replacing
   the droplet's flat tint with a true lens: capture the backdrop+letters
   (`contentLayer`) into a texture via `ShaderEffectSource`
   (`hideSource:false`, `live:true`), sample it in the droplet's own
   fragment shader, and inside the capsule mask push the sampled alpha
   toward 1 (un-premultiply → boost alpha → re-premultiply) instead of
   painting a colour. Technically worked (confirmed a real green→blue
   gradient reading through as the shape stretched across both words) but
   was **rejected on sight**: letters visibly doubled/ghosted at the mask's
   antialiased edge (dim original + boosted sampled copy, slightly
   misaligned), the result read as too bright/flat, and the rim read as a
   thick border once the interior was that bright too. Fully reverted —
   `kanata-trackbg.*` stayed, but the droplet went back to a flat,
   crossfaded tint (`droplet.tint`, `Behavior`/`ColorAnimation`,
   `Easing.InCubic`, 480ms) layered over the backdrop, not sampling it.
   **Lesson: this build has `ShaderEffectSource` available (core QtQuick,
   unlike the missing Effects/Shapes modules) and it DOES work for a lens
   effect — but "technically works" and "looks good" are different bars,
   and a lens-over-text specifically has a ghosting failure mode worth
   expecting going in, not discovering after building it.**

3. **Letters' active/inactive brightness distinction removed entirely**
   (`wordBlock.active` property and its `fg`/`fgDim` ternary + 650ms
   `Behavior` deleted; letters are now always `fgDim` when known, constant,
   no animation). This was explicitly an experiment ("remove the
   opacity... see if that fixes the blinking") to isolate one of several
   simultaneously-changing things during a mode switch. It did NOT fix the
   blinking — the real cause was elsewhere (see below) — but it was kept
   anyway since removing it wasn't harmful and simplified the file; it was
   never explicitly re-requested. **Open question for next time: now that
   the real bug is fixed, the user may want the active-word brightening
   back — it was never restored, just left out after the experiment.**

4. **Real bug #1 (genuine, fixed): momentary kanata layers hid the droplet
   entirely.** `nums` and `arrows` are layer-while-held in
   `kanata-internal.kbd` — holding space ~200ms engages `nums`, holding `v`
   engages `arrows` — and both are deliberately excluded from
   `KanataCtl.modes` so they don't show up as extra words. That exclusion
   alone doesn't stop `currentLayer` from actually BECOMING "nums"/"arrows"
   for that moment, though, and `activeIndex` resolved to `-1` whenever it
   did, which fed straight into `visible: activeIndex >= 0` on the droplet —
   so **just holding spacebar for a beat during ordinary typing made the
   whole indicator disappear**, nothing to do with switching modes at all.
   Confirmed by forcing `currentLayer` to `"nums"` directly over the raw TCP
   control socket and watching the droplet vanish. Fixed by splitting
   `activeIndex` into a `rawIndex` (the raw, possibly -1, lookup) and a
   guarded `activeIndex` that only UPDATES when `rawIndex >= 0` — a
   momentary excursion to an unknown layer just never touches it, so the
   droplet keeps resting exactly where it was.

5. **Real bug #2 (the actual "jumps to the destination then animates from
   there" cause): a live QML binding racing an explicit animation.**
   User's own, very precise description ("it jumps to the destination
   immediately and then animates from where it's supposed to") was the key
   that cracked this. `droplet.topEdge`/`bottomEdge` were declared as
   `property real topEdge: root.restTop(Math.max(0, root.activeIndex))` —
   this is a LIVE BINDING (re-evaluated every time `root.activeIndex`
   changes), not a one-time initial value, even though two
   `NumberAnimation`s also target the same properties. The instant
   `activeIndex` changed, this binding fired SYNCHRONOUSLY and snapped
   `topEdge`/`bottomEdge` straight to the new rest position — racing
   `topEdgeAnim`/`bottomEdgeAnim`'s own `.restart()` calls in the same
   handler. Confirmed by temporarily logging `onTopEdgeChanged`/
   `onBottomEdgeChanged` with `console.log(..., Date.now())`: the values
   jumped to the EXACT new target for one frame, then jumped BACK toward
   roughly the old value, then animated smoothly from there to the target —
   precisely "jumps to destination, then animates from where it's supposed
   to." Fixed by declaring both as plain literals (`property real topEdge:
   0`) and setting the real starting value exactly once via
   `Component.onCompleted`, so the two `NumberAnimation`s are the ONLY thing
   that ever writes to these properties afterward — no competing reactive
   source left to race.
   **This is the SAME pattern already fixed once this session on
   `root.activeIndex` itself** (also converted from a live binding to a
   literal + guarded assignment, for the nums/arrows bug) — but that fix
   wasn't generalized into "check every property-with-an-Animation in this
   file for the same shape," and a comment already sitting right next to
   `topEdge`/`bottomEdge` ("No Behavior here: these ARE the animation...")
   gave false confidence that this specific pitfall didn't apply, because it
   was reasoning about `Behavior` specifically rather than about declarative
   `:` bindings in general.
   Once fixed, the leading-edge duration (which had been slowed 110ms →
   200ms → 300ms while chasing this, on the theory that the *design* of
   "leading edge reaches destination fast" was itself the problem) was
   reverted back to the original 110ms — slowing it down never touched the
   actual race, it just gave the one-frame glitch more relative screen time
   to be seen, which is why the user's own feedback was "it's worse now."

### Key lesson (generalizable, likely to recur)

**In QML, `property T x: expr` where `expr` references a reactive
dependency is a LIVE BINDING, not a default value — even if `x` is also the
target of an explicit `Animation`/`NumberAnimation`/`Behavior`.** The
binding re-evaluates synchronously whenever its dependency changes, and can
race the animation's own start/restart logic, which captures "from" based
on the property's CURRENT value at that moment. The visible symptom is
exactly "snaps to the final value for a frame, then jumps back near the old
value, then animates properly" — easy to misdiagnose as the animation
design itself (duration/easing) being wrong, when the actual fix is at the
property declaration: use a plain literal initial value (no dependency) and
set the real starting value once, imperatively, via `Component.onCompleted`
(or equivalent), leaving the Animation as the sole writer from then on. This
bit this exact file twice in one session (`root.activeIndex`, then
`droplet.topEdge`/`bottomEdge`) — worth a deliberate grep for `property .*:
.*root\.` (or similar reactive-expression bindings) next to any `target:`/
`property:` reference in a `NumberAnimation`/`Behavior` elsewhere in this
codebase, rather than waiting to be bitten a third time.

### Debugging technique that actually worked

Screenshot + pixel-sampling (grim → ImageMagick crop/resize with
`-filter point` → PIL colour sampling) was the right tool for anything about
*layout, colour, or shape* — but it is NOT fine-grained enough to catch a
genuine single-frame property race. What actually found bug #2 was
temporary `console.log(value, Date.now())` instrumentation directly inside
the relevant `onXChanged` handlers, combined with redirecting `qs`'s own
stdout/stderr to a log file (`setsid -f bash -c 'qs -p ... > logfile 2>&1'`)
and grepping it after triggering the interaction — either synthetically (a
raw `exec 3<>/dev/tcp/127.0.0.1/7979` write of `{"ChangeLayer":{"new":".."}}`
is functionally identical to a real click, since both just ask kanata to
broadcast a `LayerChange` that the daemon relays the same way either way)
or, when synthetic reproduction kept NOT showing the bug the user could
reliably see live, by asking the user to trigger it for real while logging
was active. The lesson there: if a synthetic repro of a backend-level event
doesn't reproduce a UI bug the user sees from a real interaction, suspect
the RENDERING/property layer, not the backend path — don't keep trying to
make the synthetic repro "more realistic."

### Current state (as of this commit)

- `trackBg`: SDF capsule mask, static 3-colour smoothstep blend,
  `modeZoneAlpha = 0.14`.
- `droplet`: flat crossfaded tint (`droplet.tint`, `Behavior`/
  `ColorAnimation`, `Easing.InCubic`, 480ms), `coreAlpha = 0.55`,
  `rimAlpha = 1.0`, `crescentAlpha = 0.14`.
- Letters: always `fgDim` (known) / `fgA(0.25)` (unknown) — no active-state
  brightening, no per-letter `Behavior` (see open question above).
- `activeIndex`: literal initial value + guarded `onRawIndexChanged`
  assignment (ignores momentary `nums`/`arrows`).
- `droplet.topEdge`/`bottomEdge`: literal initial values + one-time
  `Component.onCompleted` seed; `NumberAnimation`s are the sole writer.
- Leading/trailing edge durations back to the original 110ms/420ms
  (direction-dependent), `InOutCubic`/`OutCubic`.
- User confirmed this state as "working how I wanted it to."
