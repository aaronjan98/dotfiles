# 2026-11-14 — Kanata lang sub-island + AltGr accent flow (Phase 2)

Continuation of the same day's earlier `kanata-island-droplet-shader.md` session, but a
genuinely separate topic: this one builds Phase 2 of project-memory/kanata-island.md —
the language sub-island UI and the real AltGr+vowel accent-type/cycle/commit flow that
replaces `accent-pick`. Branch: `kanata-lang-island` (off `main`, both in the `~/.config`
dotfiles bare repo — hypr and quickshell config live in the same repo).

## What was built

- `components/services/AccentCtl.qml` — language state (`languages`, `currentLang`,
  `setLang()`, persisted to `~/.local/state/quickshell/accent-lang`) + accent panel
  display state (`panelVisible`, `activeBase`, `activeVariants`, `activeIndex`,
  `show()`/`select()`/`hide()`). Reads `~/.config/quickshell/accents.json` as the one
  source of truth for the variant table (shared with the shell scripts via `jq`).
- `components/widgets/LangIsland.qml` — the lang pill itself, attached below
  KanataIsland's mode pill via negative Column spacing in `LeftBar.qml`.
- `components/services/AccentIpc.qml` — `IpcHandler{target:"accent"}` with
  `present()`/`select()`/`hide()`, instantiated ONCE from `FrameRoot.qml`'s laptop-only
  `Loader` (not per-screen — an IpcHandler target has to be unique process-wide, and
  FrameRoot itself is created once per screen via shell.qml's `Variants`).
- `components/widgets/AccentPanel.qml` — display-only `PanelWindow`,
  `WlrKeyboardFocus.None`, shows the variant row near the island.
- `~/.config/hypr/scripts/accent-type` / `accent-cycle` / `accent-commit` — replace
  `accent-pick` (deleted). `accent-type` types the plain base letter immediately, then
  opens the `accent` Hyprland submap (conf.d/20-binds.conf) + the panel; `accent-cycle`
  (arrow keys, submap-only) backspaces+retypes through variants; `accent-commit`
  (Return/Escape/space) exits the submap and hides the panel. `~/.config/quickshell/
  accents.json` holds the lowercase variant table; uppercase is derived in-script via
  bash's `${var^^}` (confirmed to case-fold accented Latin letters correctly under a
  UTF-8 locale, so the table doesn't need a duplicate uppercase copy).

## Key lessons (generalizable)

### 1. Two independently-translucent Rectangles will always bleed into each other
Tried three times to make LangIsland "tuck behind" the mode pill using plain overlapping
`Rectangle`s (full radius → ate into "Maj"'s "j" row; shallow overlap → visible crescent
where the two corner radii didn't match; squared top + border → the border's own flat
line crossed through "Maj", confirmed on a screenshot). The fix that actually worked:
**don't paint anything in the hidden region at all** — clip the lang pill's visual
Rectangle away above a depth tuned to clear the mode pill's own curved corner zone
(`langClipRise`), using a separate clipping Item + an oppositely-shifted child (the
"shift down to clip, shift back up to realign" trick), decoupled from how much the
Column itself shifts the two widgets together (`langOverlap`). Same root lesson as the
mode pill's OWN backdrop earlier in the day: stacked translucent Rectangles don't
"hide" anything behind a more-opaque sibling, they just blend — if you don't want to see
it, don't draw it there, don't rely on z-order + alpha to disappear it.

### 2. `qs ipc call <target> show ...` is broken — "show" collides with the `ipc show` subcommand
Declaring `function show(base: string, ...): void` on an `IpcHandler` registers and
introspects fine (`qs ipc show` lists the correct signature), but `qs ipc call <target>
show <args>` fails for ANY argument with a raw CLI11-style `The following argument was
not expected` (exit 109) instead of quickshell's normal arg-count error. Renaming the
function to `present` fixed it immediately, same signature, same call shape. Filed as
product feedback. **Never name an IpcHandler function `show`** (and probably avoid
`call`/`wait`/`listen`/`prop` too, though those weren't directly tested).

### 3. Hyprland submaps intercept VIRTUAL (wtype-injected) keystrokes too — this was the real bug
The actual root cause of "arrow keys select something then the popup immediately
closes, every single time, ~90ms later": `accent-cycle`'s own `wtype -k BackSpace` /
`wtype "$next"` calls ran WHILE the `accent` submap was still active. Hyprland's
compositor-level bind matching doesn't distinguish real hardware input from
virtual-keyboard-protocol input — so wtype's own injected keystrokes got fed back
through the submap's bind table and were misread as matching the Return/Escape/space
commit binds, undoing the very character the cycle had just typed. Confirmed by direct
trace logging (echo-to-file instrumentation in all three scripts, verified against REAL
user keypresses, not synthetic ones): every `accent-cycle` call was followed within
~90-100ms by TWO `accent-commit` calls, matching exactly the two wtype invocations per
cycle. Fixed by having `accent-cycle` drop out of the submap (`hyprctl dispatch submap
reset`) immediately before its wtype calls and re-enter (`hyprctl dispatch submap
accent`) immediately after. **Generalizable: any script that both (a) runs while a
Hyprland submap is active AND (b) injects its own keystrokes via wtype/ydotool needs to
exit the submap around the injection, or its own synthetic input can trigger its own
bindings.**

### 4. `wtype -k <ArrowKey>` cannot be used to test Hyprland arrow-key binds at all
Confirmed directly: `wtype -k Right` (also tried lowercase, keycode-based binds, with
and without modifiers) never triggers ANY Hyprland bind — plain global bind, modified
bind, submap bind, all silently no-op — while `wtype -k Escape` DOES trigger binds fine.
This is a real, specific limitation of this wtype/Hyprland combination for
navigation-key injection (not investigated further — not needed once real keypresses
confirmed the actual bug was elsewhere). **Don't trust a "no effect" result from
`wtype -k Right/Left/Up/Down` as evidence that a Hyprland arrow-key bind is broken** —
test arrow-key binds with Escape/Return/space first to confirm the mechanism, then ask
the user to test arrows for real.

### 5. Hyprland has no "catchall" bind keyword (this version, 0.52.2 — checked the binary, no such string)
Wanted: panel dismisses when you continue typing normally, not just on explicit
Return/Escape/space. Hyprland submap binds are an explicit allow-list; there's no
wildcard "any other key" bind without enumerating every key individually (and even
then, each would need to re-type itself via wtype after consuming it, to not eat the
user's actual keystroke). Decided against — user explicitly chose to keep the simple
Return/Escape/space-only design rather than build out that enumeration.

## Design decisions (diverged from the original project-memory/kanata-island.md spec)

- **Types the PLAIN base letter immediately, not the accented default.** The original
  doc said "wtypes the default variant... the character appears instantly" — user
  explicitly rejected this live ("that's not what I want... I want e to be typed by
  default, but automatically open the popup to select a different variant"). Changed
  the whole indexing scheme: the cycle is `[base-letter, variants[0], variants[1], ...]`,
  index 0 = the plain letter already typed, not the first accent.
- **No inactivity auto-commit at all.** Doc suggested ~1500ms. Tried 1500ms (confirmed
  by reproducing it directly — fires mid-glance, before a human can react) and 4000ms
  (user: "still same behavior... still times out" — still read as an arbitrary number
  fighting against actual reaction time). Removed entirely per explicit user direction:
  "the idea was that it stays up until I press the next letter or if I made a
  selection." Tradeoff accepted: walk away mid-pick and the submap stays engaged,
  capturing arrow keys, until you come back and press Return/Escape/space.

## Current state (end of session)

Branch `kanata-lang-island`, one WIP commit already made (`fe695d3`, visuals only,
before the accent scripting work). Not yet committed as of this note: FrameRoot.qml,
AccentCtl.qml (panel state + show/select/hide, no timer), AccentIpc.qml (new),
AccentPanel.qml (new), qmldir (AccentIpc registration), hypr/conf.d/20-binds.conf (MOD5
binds repointed to accent-type, new `accent` submap), hypr/scripts/accent-type|cycle|
commit (new), hypr/scripts/accent-pick (deleted). Full flow verified working end-to-end
with real keypresses: AltGr+e types `e`, arrow keys cycle through variants correctly,
Return/Escape/space commits. User was about to request a commit + `/compact` when this
note was written.

## Open items / next steps

- None blocking — the Phase 2 flow is functional and user-approved as-is.
- Possible future revisit: the "continue typing doesn't dismiss the panel" tradeoff,
  if it turns out to be annoying in practice (would need the per-key enumeration
  approach, explicitly deferred this session).
- `accents.json`'s table is still exactly the doc's original example (en/es/pt, a-e-i-o-u
  only) — fine for now, matches what was scoped.
