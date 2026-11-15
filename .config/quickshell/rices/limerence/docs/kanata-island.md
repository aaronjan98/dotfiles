# Kanata Island Subsystem

The Kanata island is the left-bar widget stack that shows which kanata layer
is active and, since Phase 3, doubles as a one-shot app/URL launcher ("exec
mode"). Like the notification subsystem, it spans more than one file
category: a TCP-bridging daemon outside Quickshell, two services, three
widgets, and a JSON data table.

This doc is the clean reference for *how it works today*. For the chronological
decision log (why things are shaped this way, what was tried and rejected,
exact wire-protocol verification against kanata's source) see
`~/.config/quickshell/project-memory/kanata-island.md` — that file is a working
spec/log, this one is the settled architecture.

## The big picture

```
kanata-internal.kbd (per host)
  |  TCP, localhost:7979, newline-delimited JSON
  v
scripts/kanata-ctl-daemon.py   (nixos-config repo, spawned by KanataCtl.qml)
  |  stdio, newline-delimited JSON
  v
KanataCtl.qml  (singleton service)
  |-- mode/layer state --> KanataIsland.qml (mode pill)
  |-- language state  --> AccentCtl.qml --> LangIsland.qml (lang pill)
  `-- exec messages    --> exec.json lookup --> Quickshell.execDetached()
```

Four related but distinct pieces live under this one subsystem:

- **Mode pill** — which sticky kanata layer is active (`default`/`capslayer`/
  `majlayer`/`execlayer`), shown as a stacked word column with a sliding
  "droplet" highlight.
- **Lang pill** — which language (`en`/`es`/`pt`) the accent-type flow below
  should use, visually tucked behind the mode pill.
- **Accent flow** — AltGr+vowel types the plain letter immediately, then lets
  arrow keys cycle to an accented variant in place (Return/Escape/space
  commits).
- **Exec mode** — tap the physical left Super key to enter a one-shot kanata
  layer where each key launches an app or URL, then bounces back to `default`.

## Why the system is split this way

### `KanataCtl.qml` owns the daemon, full stop

Only one thing in this whole subsystem spawns `kanata-ctl-daemon.py` and reads
its stdout: `KanataCtl.qml`. Both mode/layer state AND exec-mode dispatch live
here, even though they're conceptually different features, because an
`IpcHandler` target (and, similarly, a daemon `Process`) has to be unique
process-wide — splitting the daemon connection across two services would mean
two TCP clients fighting over one conceptual "the kanata connection" owner.
Exec mode's `execActions`/`runExec()` are a clearly-labeled section inside this
file rather than a separate `ExecCtl.qml` singleton for the same reason
`AccentIpc`/`AccentPanel` are only instantiated once from `FrameRoot.qml`'s
laptop-only `Loader`: a `pragma Singleton` component that nothing references
is never actually constructed by the QML engine, and KanataCtl is *already*
guaranteed to be constructed (every screen's `LeftBar.qml` references
`KanataCtl.modes`), so folding exec dispatch in here sidesteps a whole class of
"did this singleton actually load" bugs for free.

### Accent state is its own service, not folded into `KanataCtl`

Unlike exec mode, `AccentCtl.qml` is a separate singleton. The accent flow has
its own persisted language state, its own popup-visibility state, and is
driven by shell scripts via IPC rather than by kanata's push-msg mechanism —
genuinely separate data and a separate caller, unlike exec mode which is just
"a message kanata already sends, relayed to a lookup table."

## File-by-file reference

### `scripts/kanata-ctl-daemon.py` (nixos-config repo, not this repo)

Long-lived TCP client bridging kanata's control socket (port 7979) to
newline-delimited JSON on stdin/stdout. Spawned as a child process by
`KanataCtl.qml`'s `Process` element — **not** a systemd service, so it lives
and dies with the Quickshell process that spawned it (see "Restarting after a
script change" below).

Relays three kinds of kanata server messages:
- `LayerChange`/`LayerNames` → folded into one state snapshot:
  `{"connected": bool, "layer": str, "layers": [str...]}`
- `MessagePush` (sent by execlayer's `push-msg` actions) → relayed as-is, NOT
  folded into the snapshot: `{"execMsg": <value>}`. Kanata always wraps a
  pushed message as a one-element array (`{"message": ["obsidian"]}`, never a
  bare string) — this is harmless downstream because JS coerces a
  single-element array to its one element when it's used as an object
  property key, but don't be surprised by the array shape if you're reading
  the wire traffic directly.

### `components/services/KanataCtl.qml` (singleton)

- `connected`, `currentLayer`, `layers` — mode/layer state from the daemon's
  snapshot lines.
- `modes` — the 4-entry table (`default`/`capslayer`/`majlayer`/`execlayer`)
  the mode pill renders, each with a `key`, display `word`, and `colour`
  (`Appearance.modeCol*` — all four are FIXED Flat UI Colors hex values, not
  matugen-routed, so the mode pill's colour identity survives a wallpaper
  change: green=Norm/Emerald, blue=Cap/Peter River, red=Maj/Alizarin,
  yellow=Exec/Sun Flower).
- `execTableFile`/`execActions`/`runExec(name)` — exec mode's JSON-table
  lookup and dispatch (see "Exec mode data flow" below).
- The daemon's `stdout` handler checks `obj.execMsg !== undefined` **before**
  reading `obj.connected`/`obj.layer`/`obj.layers` — an exec-message line has
  none of those fields, so reading them first would incorrectly stomp
  `connected` to `false` on every exec keypress.

### `components/widgets/KanataIsland.qml`

Renders `KanataCtl.modes` as a stacked column of word-blocks (each mode's
word spelled downward, one letter per row) with a glassy shader-drawn
"droplet" sliding over whichever block is active, plus a continuous
per-mode-coloured background shader (`kanata-trackbg.frag`/`.vert`).

**The background shader is hardcoded to exactly 4 colour stops / 3
boundaries** (`colourA..D`, `boundary0..2`), matching the 4 entries in
`KanataCtl.modes` — not generalised to N colours via array uniforms (std140
array padding isn't worth it unless a 5th mode actually lands). If you add a
5th mode, you must also edit the shader source and recompile:
```bash
qsb --glsl "300es,330,440" --hlsl 50 --msl 12 -o kanata-trackbg.frag.qsb kanata-trackbg.frag
qsb --glsl "300es,330,440" --hlsl 50 --msl 12 -o kanata-trackbg.vert.qsb kanata-trackbg.vert
```
(`qsb` ships with `qtshadertools`, under its nix store `bin/` directory.) The
word-block layout math (`blockHeight`/`blockStartY`/`totalTrackHeight`) and the
droplet's own tint ARE already generic over `modes.length` — only the
background shader needs this manual step.

### `components/services/AccentCtl.qml` (singleton)

Language state (`languages`, `currentLang`, `setLang()`, persisted to
`~/.local/state/quickshell/accent-lang`) plus accent-panel display state
(`panelVisible`, `activeBase`, `activeVariants`, `activeIndex`). Reads
`~/.config/quickshell/accents.json` for the variant table — the one place
mapping a base letter + language to its accented variants, shared with the
`accent-*` shell scripts via `jq`.

Deliberately has **no inactivity auto-commit timer**. A pick stays open until
you press Return/Escape/space, or start a new pick with another AltGr+vowel —
tried 1500ms and 4000ms timers first, both read as arbitrary and fought actual
human reaction time.

### `components/services/AccentIpc.qml`

`IpcHandler{target: "accent"}` exposing `present()`/`select()`/`hide()` to the
`accent-type`/`accent-cycle`/`accent-commit` shell scripts via `qs ipc call`.
**Never name an IpcHandler function `show`** — it collides with the `qs ipc
show` introspection subcommand and silently breaks argument parsing for every
call (confirmed: exit 109, "The following argument was not expected"). This is
why the function is called `present`, not `show`.

Instantiated once (not per-screen) from `FrameRoot.qml`'s laptop-only `Loader`
— an `IpcHandler` target must be unique process-wide, and `FrameRoot` is
otherwise created once per screen via `shell.qml`'s `Variants`.

### `components/widgets/AccentPanel.qml`

Display-only `PanelWindow` (`WlrKeyboardFocus.None`, so it never steals
keyboard focus from whatever you're typing into) showing the current
base-letter + variant row, highlighting `AccentCtl.activeIndex`.

### `components/widgets/LangIsland.qml`

The lang pill, visually tucked behind the mode pill via negative `Column`
spacing in `LeftBar.qml`. Its own paint is clipped away above a tuned depth
(`Appearance.langClipRise`) rather than relying on z-order + alpha to hide the
overlap region — two independently-translucent `Rectangle`s never actually
hide one behind the other, they just blend, so if you don't want to see a
region, don't paint it there.

## Exec mode data flow

```
kanata (execlayer key, e.g. "o")
  --push-msg "obsidian"--> MessagePush over TCP
  --> kanata-ctl-daemon.py relays {"execMsg": ["obsidian"]}
  --> KanataCtl.qml: runExec(execMsg) looks up execActions["obsidian"]
  --> ~/.config/quickshell/exec.json: "obsidian": ["obsidian-remote", "new-window"]
  --> Quickshell.execDetached(["obsidian-remote", "new-window"])
```

`exec.json` is the ONE place mapping a semantic string to a real command —
kanata's `.kbd` only ever sends a short string like `"youtube"`, never the
actual command. This means **adding a new exec action is a JSON edit, not a
kanata rebuild** — but see "Hot-reloading exec.json" below, it still needs one
specific thing to actually take effect live.

### Current key map (both hosts, identical `execlayer` block)

| Key | Action | Command |
|---|---|---|
| `y` | youtube | `firefox https://youtube.com?authuser=1` |
| `d` | vesktop | `vesktop` |
| `f` | firefox | `firefox` |
| `h` | home | `firefox http://home.home` |
| `p` | photos | `firefox http://photos.home` |
| `n` | cloud | `firefox https://cloud.janovitch.com` |
| `a` | amazon | `firefox https://www.amazon.com` |
| `r` | radarr | `firefox http://radarr.home` |
| `j` | movies | `firefox http://movies.home` |
| `s` | sonarr | `firefox http://sonarr.home` |
| `o` | obsidian | `obsidian-remote new-window` (same command as fuzzel's "Obsidian (Spawn Window)" entry — see `nixos-config/modules/obsidian-ipc.nix`) |
| `g` | ghostty | `ghostty` |
| `q` | kitty | `kitty` |
| `t` | tiktok | `firefox https://tiktok.com` |
| `l` | links | `firefox http://links.home` |

Every other key in `execlayer` just bounces back to `default` with no side
effect (`@exExit`) — one-shot by construction, there's no key, mapped or not,
that leaves you stuck in the layer.

### Entry/exit mechanics (kanata side, `kanata-internal.kbd`)

- **Entry**: tap the PHYSICAL left Super key (next to left Alt). This key was
  previously absent from `defsrc` entirely (passed through untouched) — it is
  NOT the same thing as the home-row-mod `lmet` OUTPUT that `dmet`/`kmet`/the
  chord defvars already emit when held. `lmet_exec` is a `tap-hold-press`:
  tap → `(layer-switch execlayer)`, hold → passthrough `lmet` (so Super+
  anything still works as a normal Hyprland modifier everywhere). Only bound
  in `default` — every other layer just passes the physical key through as
  plain `lmet`.
- **Exit**: one-shot. Every mapped key is `(multi (push-msg "...")
  (layer-switch default))`; every unmapped key is `exExit`, just
  `(layer-switch default)`.

### Adding a new exec action

1. Pick an unused key in `execlayer` (check both hosts'
   `hosts/*/kanata/kanata-internal.kbd` — they're kept byte-identical outside
   the per-host `defcfg` device-matching block).
2. Add an alias: `exFoo (multi (push-msg "foo") (layer-switch default))`, and
   use `@exFoo` at that key's position in the `(deflayer execlayer ...)`
   block, in BOTH host files.
3. Validate: `kanata --check -c hosts/<host>/kanata/kanata-internal.kbd`.
4. Add the `"foo": [...]` entry to `~/.config/quickshell/exec.json`.
5. `nixos-rebuild switch` + restart `kanata-internal` on the host (the `.kbd`
   change needs this; `exec.json` does not — see below).

## Operational gotchas (learned the hard way, Phase 3 deployment)

### A running `Process` does not auto-respawn if killed externally

`KanataCtl.qml`'s daemon `Process` has `running: true`, which many QML
Process-like APIs treat as "keep this alive" — Quickshell's does not. Kill the
daemon's PID out from under Quickshell and it simply stays dead; nothing
relaunches it. If you need to restart the daemon script, restart the whole
Quickshell process, not just the daemon PID.

### QML hot-reload does NOT recreate an already-running `Process`

Editing `kanata-ctl-daemon.py` on disk has **no effect on an already-running
daemon process** — Python doesn't hot-reload, and editing a `.qml` file (which
does trigger Quickshell's "Reloading configuration..." live-reload) does not
tear down and respawn a `Process` child that's already running, even though
it DOES re-evaluate plain QML state like `FileView` content. This combination
caused a real bug this session: the daemon kept running pre-fix code for
several edits while every other change appeared to apply instantly. **After
changing `kanata-ctl-daemon.py`, you must either `qs -r` (check first that
this actually recycles the Process — it wasn't verified to in this session)
or do a full restart** (kill the `qs`/`quickshell` process, relaunch with `qs
-p ~/.config/quickshell/rices/current/shell.qml`) to guarantee the daemon
picks up the new script.

### `FileView` needs `watchChanges: true` to hot-reload a data file

`exec.json`'s `FileView` in `KanataCtl.qml` has `watchChanges: true`
specifically because without it, editing `exec.json` has no effect until the
next full Quickshell restart — which would defeat the entire point of keeping
the key→command table out of the `.kbd`. If you add another JSON-table-backed
service, set this explicitly; it is not the default.

### `.kbd` changes always need a real deploy

Editing `hosts/*/kanata/kanata-internal.kbd` has zero effect until
`nixos-rebuild switch` + a `kanata-internal` service restart on that host —
`kanata --check -c <file>` validates syntax fast and cheaply (use it before
every real edit) but does not reload the running remapper.

## Relevant files

- `components/services/KanataCtl.qml`, `components/services/AccentCtl.qml`,
  `components/services/AccentIpc.qml`
- `components/widgets/KanataIsland.qml`, `components/widgets/LangIsland.qml`,
  `components/widgets/AccentPanel.qml`
- `components/widgets/kanata-trackbg.frag`/`.vert` (+ `.qsb`),
  `components/widgets/kanata-droplet.frag`/`.vert` (+ `.qsb`)
- `config/Appearance.qml` — `modeCol*`/`lang*` tokens
- `~/.config/quickshell/accents.json`, `~/.config/quickshell/exec.json`
- `~/nixos-config/scripts/kanata-ctl-daemon.py`
- `~/nixos-config/hosts/{thinkpad-t14,framework-13}/kanata/kanata-internal.kbd`
- `~/nixos-config/docs/ROADMAP.md` — nixos-config-side planning/status
- `~/.config/hypr/scripts/accent-type`, `accent-cycle`, `accent-commit`
- `~/.config/hypr/conf.d/20-binds.conf` — the `accent` kanata-adjacent
  Hyprland submap (unrelated to kanata's own `execlayer` — this one is a
  Hyprland submap used by the accent-cycle flow, a separate mechanism)
