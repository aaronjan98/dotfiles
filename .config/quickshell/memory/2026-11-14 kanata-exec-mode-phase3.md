# 2026-11-14 — Kanata exec mode (Phase 3): naming, 4th mode colour stop, push-msg plumbing

Continuation of the same day's `kanata-lang-island accent-flow.md` session, same branch
(`kanata-lang-island`, off `main`, `~/.config` dotfiles bare repo). Distinct topic: this
is the fourth kanata island mode (the one the spec called "launcher mode"/`L`) going from
a placeholder to a fully wired-up, one-shot app/URL launcher.

## What was built

1. **Renamed "launcher mode" -> "Exec"**, user's choice over "Shell" (mechanism is
   push-msg-triggered command execution, not an interactive shell session) across
   `Appearance.qml` (`modeColLauncher` -> `modeColExec`), `KanataCtl.qml`'s mode table
   (`execlayer`/`Exec`), and the spec docs (`project-memory/kanata-island.md`,
   `docs/ROADMAP.md`).
2. **Colour**: user wanted it yellow, not the matugen-`error`-role fallback it had.
   Switched to a FIXED hex (`#f1c40f`, Flat UI Colors "Sun Flower") to match how
   Norm/Cap/Maj are already fixed Flat UI picks (Emerald/Peter River/Alizarin) rather
   than matugen-routed -- confirmed by checking the actual hex values against
   flatuicolors.com's palette, they're an exact match, so Exec now completes that same
   designer palette instead of being the odd one out.
3. **Extended the island's background shader from 3 colour stops/2 boundaries to 4/3**
   (`kanata-trackbg.frag`/`.vert`: added `colourD`, `boundary2`, a third `smoothstep` +
   `mix` in the blend chain) -- found and fixed BEFORE it shipped, not after a visual
   bug report, by reading the shader's own comment ("Hardcoded to exactly 3 modes... not
   worth generalising... until that actually changes") before wiring Exec into the live
   `KanataCtl.modes` array. Recompiled via `qsb --glsl "300es,330,440" --hlsl 50 --msl 12`
   (binary at `/nix/store/*-qtshadertools-6.10.2/bin/qsb`). `KanataIsland.qml`'s layout
   math (`blockHeight`/`blockStartY`/`totalTrackHeight`) and the droplet's own tint were
   already generic over `modes.length` -- only the trackBg shader was hardcoded.
4. **Phase 3 push-msg plumbing, end to end**:
   - `~/.config/quickshell/exec.json` (new) -- semantic-string -> argv table, same design
     split as `accents.json`: kanata's `.kbd` only ever sends a short string like
     `"youtube"`; this file is the ONE place mapping that to the real command, so adding
     an exec action later is a JSON edit, not a kanata rebuild.
   - `KanataCtl.qml` -- added `execTableFile`/`execActions`/`runExec()`, a `FileView` to
     load `exec.json`, and a branch in the daemon's `stdout` handler: `obj.execMsg` is
     checked (and returned from) BEFORE the `connected`/`currentLayer`/`layers`
     assignments, because a relayed exec message has none of those fields and would
     otherwise stomp `connected` to `false`.
   - `scripts/kanata-ctl-daemon.py` -- added a `MessagePush` branch to `handle_message`,
     emitting `{"execMsg": <value>}` as a one-off relay line (NOT folded into
     `state.snapshot()` -- it's an event, not state). Field is `message`, not `msg` --
     this was already verified against kanata's real source in this same spec doc from
     the Phase 1 session; didn't need to re-derive it, just had to go find it.
   - `kanata-internal.kbd` (BOTH `thinkpad-t14` and `framework-13`, kept byte-identical
     outside the pre-existing per-host `defcfg` device-matching block) -- added the
     physical `lmet` key to `defsrc` (43rd key; previously ABSENT, meaning the real
     left-Super key next to left-Alt passed through kanata completely untouched --
     distinct from the home-row-mod `lmet` OUTPUT that `dmet`/`kmet`/the chord defvars
     already emit, which is a different, pre-existing thing and was never at risk of
     colliding), a `lmet_exec` tap-hold alias (tap = `layer-switch execlayer`, hold =
     passthrough `lmet`) bound only in `default` (every other layer just passes the
     physical key through as plain `lmet`, no entry behaviour there), 13 `ex*` aliases
     (`multi (push-msg "...") (layer-switch default)`) plus a shared `exExit
     (layer-switch default)` for every unmapped key, and a new `(deflayer execlayer ...)`
     block with one entry per all 43 `defsrc` positions (one-shot by construction: no
     key, mapped or not, can leave you stuck in the layer).
   - Verified the FULL scheme (`multi`+`push-msg`+`layer-switch`, the tap-hold entry
     alias, and the real 43-position `.kbd` edits on both hosts) with `kanata --check`
     before considering it done -- caught nothing wrong, but this is cheap and would
     have caught a syntax mistake before a `nixos-rebuild switch` + keyboard-remapper
     restart, which is a much higher-cost place to find one.

## Key map (final, user-specified)

`y`=youtube (youtube.com?authuser=1), `d`=vesktop, `f`=firefox (bare), `h`=home.home,
`p`=photos.home, `n`=cloud.janovitch.com, `a`=amazon.com, `r`=radarr.home,
`j`=movies.home, `s`=sonarr.home, `o`=obsidian, `g`=ghostty, `q`=kitty. URL opens all go
through `["firefox", "<url>"]` (matches the existing `modules/imgview.nix` pattern of
calling `firefox` directly rather than relying on `xdg-open`'s mime defaults, which
aren't verified to be configured on this system). `.home` domains are plain `http://`
(matches `hosts/common/default.nix`'s existing `home.home` usage); `youtube`/`amazon`/
`cloud` are `https://`.

## Key lessons (generalizable)

### 1. Read a shader's own "why" comment before extending the thing it's attached to
`kanata-trackbg.frag` already said, in its own comment, that it was hardcoded for
exactly 3 modes and explicitly said *when* to revisit that ("until that actually
changes"). That moment arrived this session. Finding this BEFORE wiring the 4th mode
into the live `modes` array (rather than after a "the exec zone shows the wrong colour"
bug report) turned a debugging session into a 15-minute planned shader edit. The
general habit: before adding the Nth item to any array a sibling file consumes
positionally (not by iterating `.length`), grep that sibling for how it actually reads
the array — comments admitting "hardcoded to N" are a gift, not a nuisance.

### 2. A physical key "already used" in config and a key *name* used as an output value are different things
`lmet` appeared all over this `.kbd` file already (`dmet`'s hold action, `w_chord`,
`g_chord`, `launch_chord`) — all as OUTPUT values other keys emit when held. The actual
PHYSICAL left-Super key was never in `defsrc` at all, meaning it passed straight through
untouched. The ROADMAP's own stated worry ("lmet is already a chord modifier... tap
timeout may misfire") was conflating these two: the chord-modifier risk applies to typed
OUTPUT collisions (would a key whose hold-action is `lmet` ever get misread while in
exec mode?), not to the real worry, which was always "is the physical key already doing
something." It wasn't. Worth the ten minutes of grepping `defsrc`/`defalias` before
trusting a stated risk at face value, especially one written by an earlier, separate
research pass that may not have had this specific question in mind when it wrote that
line.

### 3. `kanata --check` validates fast and cheaply — use it before every real `.kbd` edit, not just once at the end
Built the exact entry/exit/push-msg scheme in a scratch `.kbd` file first
(`tap-hold-press` into a named layer, `multi` combining `push-msg` + `layer-switch`) and
confirmed it with `--check` before touching the real files, then `--check`ed the real
files again after. Total cost: a few seconds per check, using the same kanata binary
already in the nix store (no package install needed). This is the same category of
cheap-verification-before-trusting-a-design as the shader comment lesson above —
`--check` cannot tell you the UX is right, but it tells you the syntax won't blow up a
live keyboard remapper restart, which is the expensive thing to get wrong here.

### 4. A Quickshell `Process` does not auto-respawn, and live-reload does not restart one that's already running
Deployed Phase 3 (`nixos-rebuild switch` + `kanata-internal` restart, confirmed via a
direct TCP probe that `execlayer` was in kanata's own `RequestLayerNames` response), then
tested with real keypresses. First real test: kanata's raw TCP stream showed the correct
`LayerChange`→`MessagePush`→`LayerChange` sequence (confirmed via a scratch Python TCP
client watching the socket directly), but nothing launched. Root cause: the daemon
bridge process (`kanata-ctl-daemon.py`, spawned by `KanataCtl.qml`'s `Process`) had been
running continuously since BEFORE the `MessagePush`-relay code was added to it earlier in
the session -- Python doesn't hot-reload, so it was silently still running the pre-fix
version. Killing that PID directly to force a respawn did NOT work -- Quickshell's
`Process{running:true}` does not auto-respawn an externally-killed child, confirmed by
`ps`/`ss` staying empty afterward. Fix needed a full Quickshell restart (kill the `qs`
process, relaunch with `qs -p ~/.config/quickshell/rices/current/shell.qml`), not just
restarting the daemon. Separately, `exec.json` edits turned out to need
`FileView.watchChanges: true` on its loader in `KanataCtl.qml` -- without it, a `FileView`
only re-reads on the next full component reload, not on a live file edit, which would have
quietly defeated the entire "exec.json edit, no kanata rebuild" design goal. Both fixes
and a full writeup are now in the clean reference doc, `docs/kanata-island.md`, under
"Operational gotchas" -- worth reading before touching this daemon again. One reasonable
step not tried first: Quickshell's own `CONTEXT.md` documents a lighter `qs -r` reload
command; went straight to a full kill+relaunch instead under debugging time pressure.

Separately (not a bug in this subsystem, surfaced while debugging why `o` seemed to do
nothing): Obsidian's Local REST API `workspace:new-window` command returns `HTTP 204`
(success) but didn't visibly create a new Hyprland window across two test calls (`hyprctl
clients` window count stayed flat) -- the same command the pre-existing fuzzel "Obsidian
(Spawn Window)" entry uses (`nixos-config/modules/obsidian-ipc.nix`'s `obsidian-remote
new-window`). After the Quickshell restart above, a debug trace confirmed `KanataCtl.qml`
was resolving `obsidian` to the correct `["obsidian-remote","new-window"]` command, and
the user confirmed it then worked -- so the earlier failures were most likely the
stale-daemon bug, not a real problem with the REST command itself, though that command's
reliability outside a real UI interaction remains a loose end worth remembering if `o`
ever seems to silently no-op again.

## Current state (end of session)

**Deployed and working** on the ThinkPad, confirmed with real keypresses: entry tap,
several mapped keys including the trickier `obsidian` one, and the unmapped-key no-op.
Final key map has 15 entries -- the original 13 plus `t`=tiktok and `l`=links.home, added
after the initial deploy. `exec.json` live-reloads correctly now (`watchChanges: true`).
Clean, settled-architecture reference doc written: `docs/kanata-island.md`, registered in
`docs/README.md`'s map. This project-memory doc's own "Open items" section has been
updated to point there rather than duplicate the key map going forward.

## Open items / next steps

- `t`/`l` need one more `nixos-rebuild switch` + `kanata-internal` restart on each host
  (both `.kbd` files already updated and `kanata --check`-valid) -- not yet done as of
  this note.
- Framework-13 has never been deployed/tested at all for this feature -- only confirmed
  byte-identical to the ThinkPad's file (outside the per-host `defcfg` block) and
  `kanata --check`-valid. No real-keypress confirmation on that host yet.
- The mode island's own visual check: Exec should render as a 4th dimmed word-block
  ("Exec") below Maj with a correctly-yellow static background zone -- the shader change
  was confirmed not to crash Quickshell, but still hasn't been pixel-checked on screen.
