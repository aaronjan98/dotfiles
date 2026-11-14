# Kanata Island — Mode Indicator + Language Sub-Island

## Goal

A two-pill island in the **bottom-left** corner of the left bar that shows, and
controls, two orthogonal pieces of keyboard state:

1. **Mode** — which Kanata layer is currently active (`N` normal, `C` caps, `M` major, …)
2. **Language** — which accent language is active (`en`, `es`, `pt`, …), which decides
   what character an AltGr+vowel press types by default

Secondary goal, and the reason the language pill exists at all: replace the current
"popup first, nothing typed until you choose" accent flow with **type the language
default immediately, then optionally arrow-key to a different variant, which replaces
the character in place**.

## Ownership

Primary owner: Quickshell `limerence`.

Spans two repos:

- `~/.config/quickshell/rices/limerence/` — island, panel, services (this repo)
- `~/nixos-config/hosts/*/kanata/kanata-internal.kbd` — TCP server, mode layers
- `~/nixos-config/scripts/kanata-ctl-daemon.py` — TCP ↔ stdio bridge (built; see Phase 1)
- `~/.config/hypr/conf.d/20-binds.conf` + `~/.config/hypr/scripts/accent-*` — accent flow

## Non-Goals

- Do not show momentary layers as modes (see "Which layers are modes" below).
- Do not change the physical keyboard layout or XKB variant. `altgr-intl` and the
  existing kanata layout stay exactly as they are.
- Do not make the accent panel a chooser you must interact with. It is a refinement
  HUD over a character that has *already* been typed.
- Do not grab keyboard focus anywhere in the accent flow (see "The focus constraint").
- Do not reimplement `accent-pick`'s fuzzel popup. It gets replaced, not wrapped.

---

## Verified facts about the current system

Checked directly on 2026-11-13 against kanata 1.9.0 as deployed
(`/nix/store/spfv6r2442ax26jrlb12ha6210kqs17s-kanata-1.9.0/bin/kanata`). Recorded so
this does not have to be re-derived.

### Kanata TCP protocol

Confirmed two ways: the binary's serde variant-name strings, and then pinned exactly by
reading `tcp_protocol/src/lib.rs` and `src/tcp_server.rs` from the **v1.9.0 tag** (not
`main` — `main` has since added a subscription system this build doesn't have) at
`github.com/jtroo/kanata`. Both enums are struct-variants, so serde's default external
tagging gives `{"Variant": {field: value, ...}}` for every one, **including the
empty-field variants** — `RequestLayerNames` is `{"RequestLayerNames": {}}`, never a bare
string.

Client → kanata (`ClientMessage`):

| Message | Fields |
|---|---|
| `ChangeLayer` | `new: String` — calls `change_layer()` directly, no ack, no validation |
| `RequestLayerNames` | `{}` |
| `RequestCurrentLayerName` | `{}` |
| `RequestCurrentLayerInfo` | `{}` |
| `ActOnFakeKey` | `name: String`, `action` (`"Press"`/`"Release"`/`"Tap"`/`"Toggle"`) |
| `SetMouse` | `x: u16`, `y: u16` — **does not work on Linux** ("setmouse does not work in
  Linux yet"), don't plan around it |

Kanata → client (`ServerMessage`):

| Message | Fields |
|---|---|
| `LayerChange` | `new: String` |
| `LayerNames` | `names: [String]` |
| `CurrentLayerInfo` | `name: String`, `cfg_text: String` |
| `CurrentLayerName` | `name: String` |
| `ConfigFileReload` | `new: String` |
| `MessagePush` | `message: Value` — **field is `message`, not `msg`** |
| `Error` | `msg: String` |

The connection itself is a bare `TcpStream`; the server reads `ClientMessage` values
back-to-back via `serde_json::Deserializer::into_iter`, which is self-delimiting and
doesn't require newlines on input, but every `ServerMessage::as_bytes()` appends one on
output — so treating the socket as newline-delimited JSON (as the daemon below does) is
correct and simpler than a streaming JSON parser. **On connect, kanata immediately sends
a `LayerChange` for the current layer**, so a client never has to ask for initial state.
`RequestCurrentLayerInfo`/`RequestCurrentLayerName` exist but the connect-time push
already covers what Phase 1 needs — the daemon uses `RequestLayerNames` instead, once on
connect, to get the full layer list.

Verified against a reference `ClientMessage`/`ServerMessage` exchange over a mock TCP
server standing in for kanata (built, not run against the real kanata process — see
"Why the daemon wasn't tested against real kanata" below).

### `cmd` actions are compiled out of this build

Starting kanata logs `NOTE: kanata was compiled to never allow cmd`. The `Cmd`,
`CmdOutput` and `CmdLog` actions parse but are refused at runtime. This **invalidates
the nixos-config ROADMAP plan to implement launcher mode via `cmd` actions.**

Three ways out, in preference order:

1. **`push-msg` + TCP** (recommended). Kanata has a `push-msg` action that sends an
   arbitrary string to connected TCP clients as `MessagePush`. The daemon relays it,
   Quickshell acts on it. No `cmd`, no package override, and it reuses the same socket
   the mode island already needs.
2. Have kanata emit an unusual chord and bind it in Hyprland (what `$launch_chord`
   already does today for Tab/`\`).
3. `nixpkgs#kanata-with-cmd` — exists, same 1.9.0. Last resort; `cmd` is disabled
   upstream for a reason and it widens kanata's blast radius to arbitrary execution.

### Unicode output works on Linux

`(unicode é)` and `(macro bspc (unicode ê))` both pass `--check`, and the binary
contains the Linux uinput unicode machinery ("valid keycodes for unicode", "Created
device"). So a fully-in-kanata accent engine is *possible* — it is not the recommended
path (see "Why not do accents inside kanata"), but the option is real.

### Which layers are modes

`kanata-internal.kbd` has five layers, and they split into two kinds:

| Layer | Entered by | Kind |
|---|---|---|
| `default` | `@cap_exit` tap, or resting state | **sticky** |
| `capslayer` | tap Left Shift → `(layer-switch capslayer)` | **sticky** |
| `majlayer` | tap Right Shift → `(layer-switch majlayer)` | **sticky** |
| `arrows` | hold `v` → `(layer-while-held arrows)` | momentary |
| `nums` | hold space → `(layer-while-held nums)` | momentary |

Only the three sticky layers are **modes** in the sense the island cares about — they
persist until you change them, they are meaningful to display at rest, and they are
valid `ChangeLayer` targets for click-to-switch.

`arrows` and `nums` last only as long as a key is held. Giving them letters would make
the island flicker during normal typing and clicking them would be meaningless (the
layer pops the instant the held key releases). **Exclude them.** The original ROADMAP
entry listed `N / C / M / L` without noting why `arrows`/`nums` were absent — this is
the reason.

### Port 7979 is free

`ss -ltnp` shows nothing on it.

---

## Visual design

Two pills of the **same rounded shape** (`C.Appearance.bubbleRadius`), stacked
vertically and **overlapping**, anchored above the power icon in the bottom-left:

```
   ┌────┐
   │ •N•│   mode pill — on top, full fg, normal bubbleBg
   │  C │
   │  M │
   │  L │
   ╞════╡   ← overlap seam (mode pill's border draws over the lang pill)
   │•en•│   lang pill — behind, darker fill, slightly dimmer text
   │ es │
   │ pt │
   └────┘
     ⏻     power icon (unchanged)
```

- The **mode pill renders above** the lang pill (`z` ordering), and the lang pill is
  offset downward so only its lower portion is visible. The darker fill is what sells
  "this one is underneath".
- Both pills are always visible. Nothing expands, nothing is hidden, no dismiss path.
- Each pill has its own **selection bubble**: a small rounded rect behind the active
  entry that animates its `y` when the selection changes — same feel as `DotTrack`'s
  sliding pill (`C.Appearance.animMsFast`, `Easing.OutCubic`).
- The **mode pill tints per mode** so the current mode is readable without reading the
  letter. New `Appearance.qml` tokens: `modeColDefault`, `modeColCaps`, `modeColMaj`,
  `modeColLauncher`.
- The lang pill does **not** tint per language — one tint is enough signal, and two
  competing colour channels in a 2cm island is noise.

### Implementation notes

- Both pills are `W.BubbleItem` instances in a `Column` with **negative spacing**
  (roughly `-C.Appearance.bubbleRadius`) to produce the overlap. `BubbleItem` already
  does radius + border + `bubbleBg` + content padding, so neither pill needs new
  chrome.
- `BubbleItem` sets `clip: true`, so the selection bubble can't bleed past the pill.
- Letters use a monospace-ish fixed advance so the selection bubble is the same width
  on every row; size from `C.Appearance.pillFont`.
- The lang pill's fill: derive from `bubbleBg` rather than hardcoding — e.g.
  `Qt.darker(C.Appearance.bubbleBg, 1.3)` — so it tracks the wallpaper-keyed
  `_bubbleA` opacity logic instead of fighting it.
- Vertical budget: the left bar lane is `C.Appearance.leftW` wide (`nixBubbleSize`),
  and the space between the centred workspace `BubbleItem` and the bottom `PowerIcon`
  is currently empty. Note this competes with the planned app-launcher dock in the
  same gap (quickshell ROADMAP, "Left bar: app launcher dock") — the island takes the
  bottom of that gap, the dock would take the top.

---

## Phase 1 — mode island

### 1. Kanata config changes

**`tcp-port` is not a `defcfg` directive on this build** — confirmed by `--check`
(`Unknown defcfg option tcp-port`). The real mechanism is the NixOS module's own
`port` option, independent of the raw `configFile` both hosts already point at:

```nix
# modules/kanata.nix, shared by both hosts via hosts/common/default.nix
services.kanata.keyboards.internal.port = 7979;
```

This generates `--port 7979` on the systemd unit's `ExecStart` and — this is the part
that would be easy to miss doing it by hand — also flips the service's hardening open
just enough: `IPAddressAllow = localhost`, `PrivateNetwork = false`. Verified by
building (`nixos-rebuild build --flake .#thinkpad-t14`) and reading the generated
`kanata-internal.service`: `ExecStart` carries `--port 7979` and both those hardening
lines flip correctly, for both hosts (the module is shared).

No `.kbd` file changes, no new layers, no changed bindings in Phase 1.

### 2. `~/nixos-config/scripts/kanata-ctl-daemon.py` — **built**

Needed because **Quickshell's `Socket`/`SocketServer` wrap `QLocalSocket`/
`QLocalServer`** (confirmed by reading `quickshell-io.qmltypes` in the deployed
`quickshell-0.3.0` — the error signal type is literally `QLocalSocketError`) — unix
domain sockets only, no TCP host/port form. The daemon bridges 7979 to a plain stdio
pipe Quickshell already knows how to drive.

Mirrors the existing `obs-ctl-daemon.py` contract, so the QML side is a copy-shaped
sibling of `ObsCtl.qml`:

- Connects to `127.0.0.1:7979`, reconnects with backoff (2s, doubling to a 15s cap) when
  kanata restarts (it does, on every `nixos-rebuild switch` that touches the config).
- Emits a full state snapshot as one JSON line on stdout whenever anything changes:
  `{"connected": true, "layer": "capslayer", "layers": ["default","arrows",...]}`
- Reads JSON commands on stdin: `{"cmd":"set_layer","layer":"default"}`,
  `{"cmd":"refresh"}` — translated to kanata's own `{"ChangeLayer":{"new":...}}` /
  `{"RequestLayerNames":{}}` wire shapes.
- Sends `RequestLayerNames` once on connect so the island gets the full layer list (the
  connect-time push only carries the *current* layer, via `LayerChange`).

**Tested, but not yet against the real kanata process** — see "Why the daemon wasn't
tested against real kanata" below. Verified instead against a mock TCP server built
from the exact `ClientMessage`/`ServerMessage` shapes in kanata's own v1.9.0 source: the
connect handshake (`LayerChange` then `LayerNames` after the daemon's `RequestLayerNames`),
a `set_layer` command round-tripping through `ChangeLayer` → `LayerChange` → an updated
snapshot, and `refresh`. All passed.

### 3. `components/services/KanataCtl.qml` — **built**

Singleton, registered in `components/services/qmldir`. Same `Process` +
`stdinEnabled` + `SplitParser` shape as `ObsCtl.qml`.

```qml
property bool connected: false
property string currentLayer: "default"   // NOT "layer" -- see pitfall below
property var layers: []
function setLayer(name) { send({ cmd: "set_layer", layer: name }) }
```

**Pitfall hit while building this**: `Item` has a built-in grouped property named
`layer` (`QQuickItem::layer`, used for GPU layer-effect compositing) that is `FINAL`.
Declaring `property string layer: "default"` on an `Item`-derived singleton fails at
load time with `Cannot override FINAL property` — Quickshell reports it as a cascading
"Type X unavailable" chain all the way up through every file that (transitively)
imports the services `qmldir`, which makes the actual cause easy to miss. Fixed by
naming it `currentLayer` instead.

Mode table lives here, not in the view:

```qml
readonly property var modes: [
  { key: "default",   letter: "N", colour: C.Appearance.modeColDefault  },
  { key: "capslayer", letter: "C", colour: C.Appearance.modeColCaps     },
  { key: "majlayer",  letter: "M", colour: C.Appearance.modeColMaj      },
]
```

`L` (launcher) and any future script-execution mode get appended here once the
corresponding layer exists in the `.kbd`. Entries whose `key` is not in `layers` should
render dimmed-and-unclickable rather than vanish, so a missing layer is visible as a
config problem instead of silently absent.

### 4. `components/widgets/KanataIsland.qml` — **built (mode pill only; lang pill is Phase 2)**

Hosted from `LeftBar.qml`, anchored `bottom: powerIcon.top` with a `C.Appearance.m6`
margin. Clicking a mode letter calls `KanataCtl.setLayer(key)`; the selection bubble
follows `KanataCtl.currentLayer`, so it is driven by kanata's own `LayerChange` echo
rather than by local optimism — if the switch fails, the UI correctly doesn't move.

Implementation: a `BubbleItem` containing a fixed-size `Column` of letter cells
(`C.Appearance.modeCellSize` square, `modeCellGap` apart) plus one sliding highlight
`Rectangle` positioned by `y: activeIndex * (cell + gap)` with a `Behavior on y` —
simpler than reusing `DotTrack` (which grows/shrinks dot extents; this wants a
fixed-size highlight sliding behind fixed-size letters, not resizing dots). A cell
whose `key` isn't yet in `KanataCtl.layers` renders dimmed and non-clickable. Per-mode
tint comes from `modelData.colour` (`Appearance.modeCol*`, § below) via a
`Behavior on color` on the highlight.

Follow the popup/cursor conventions from ROADMAP "Architectural foundations" §1:
`PointingHandCursor` on every clickable letter.

### Phase 1 done when

Tapping Left Shift moves the bubble to `C`, tapping Caps moves it back to `N`, and
clicking `M` in the island puts the keyboard in `majlayer`.

---

## Phase 2 — language sub-island + accent refine flow

### The focus constraint (read this before writing any code)

**The accent panel must never take keyboard focus.** `wtype` injects through the
virtual-keyboard protocol, which delivers to whatever surface holds keyboard focus. If
the panel grabs focus to read arrow keys, every `wtype` lands in the panel instead of
the user's app and the whole feature silently does nothing.

So: the panel is **display-only** (`WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`),
and the arrow keys are captured by a **Hyprland submap**, which intercepts keys globally
without moving surface focus. This inverts the normal popup pattern in this codebase
(ROADMAP §1 says every popup needs `keyboardFocus` + an Escape handler) — this one is
the deliberate exception, and it needs a comment in the file saying so.

### Flow

Trigger stays what it is today: AltGr+vowel, i.e. the `MOD5, <vowel>` binds in
`conf.d/20-binds.conf`. Muscle memory unchanged, `accent-pick` swapped out underneath.

1. `MOD5, e` → `accent-type e`
   - reads the active language from the lang state file
   - `wtype`s the **default** variant for (lang, `e`) — the character appears instantly
   - writes `{base, variants, index: 0}` to `$XDG_RUNTIME_DIR/accent-state.json`
   - `qs ipc call accent show e` → panel appears next to the island
   - `hyprctl dispatch submap accent`
2. In submap `accent`:
   - `Right`/`Down` → `accent-cycle next`, `Left`/`Up` → `accent-cycle prev`
   - `Return`/`Escape`/`space` → `accent-commit`
   - everything else passes through to the app untouched (submaps only override bound
     keys), so continuing to type just works
3. `accent-cycle` → `wtype -k BackSpace`, then `wtype` the new variant, then
   `qs ipc call accent select <i>`
4. `accent-commit` → `hyprctl dispatch submap reset` + `qs ipc call accent hide`
5. **Inactivity timeout**: `AccentCtl` runs a ~1500ms `Timer`, reset on every `select`,
   that fires `accent-commit` on expiry. Without this, a submap you forget to exit
   eats your arrow keys indefinitely — this is the one failure mode that would make the
   feature worse than what it replaces, so build the timeout in the first pass, not later.

### Two risks to test early

- **AltGr may still be physically held** when `accent-type` runs `wtype`. Mod5 being
  logically down could re-trigger the `MOD5, <vowel>` bind or produce the wrong keysym.
  `accent-pick` never hit this because its fuzzel popup took focus and the user let go
  first. Mitigation to try: `wtype -m altgr` (release the modifier) before typing.
- **`wtype -k BackSpace` must delete exactly one grapheme** in ghostty, kitty, nvim
  (insert mode), Firefox and GTK fields. In nvim *normal* mode BackSpace moves the
  cursor instead of deleting, so the flow misbehaves there — acceptable (you don't type
  accents in normal mode), but worth knowing rather than discovering.

### Variant tables — one source of truth

New `~/.config/quickshell/accents.json`, read by the shell scripts (`jq`) and by
Quickshell (`FileView`). Per CONTEXT.md's "do not duplicate responsibilities", the
table must not be copied into both.

```json
{
  "languages": ["en", "es", "pt"],
  "variants": {
    "en": { "a": ["á","ã","â","à","ä"], "e": ["é","ê","è","ë"], ... },
    "es": { "a": ["á","à","ä"],         "e": ["é","ê","è"],     ... },
    "pt": { "a": ["ã","á","â","à"],     "e": ["ê","é","è"],     ... }
  }
}
```

Order matters: **index 0 is what gets typed immediately**, the rest is the cycle order.

- `en` keeps today's `accent-pick` ordering verbatim (`á ã â à ä`, …) so nothing
  regresses on day one.
- `es` leads with the acute accent, `pt` leads with the tilde on `a`/`o` and the
  circumflex on `e`.
- Uppercase comes from the existing `MOD5 SHIFT` binds, same as today.
- `fr` is the obvious fourth; adding it should be a JSON edit and one array entry, with
  no QML or script change. If it isn't, the table isn't factored right.

Out of scope: `ñ` (`AltGr+n`) and `ç` (`AltGr+,`) already type directly as single
keysyms and need no picker. See the keyboard section of `~/nixos-config/MEMORY.md`.

### Language state

Quickshell owns it. Clicking a language in the lang pill writes the code to
`~/.local/state/quickshell/accent-lang` (plain text, one line) and that file is what
`accent-type` reads. A file rather than an IPC query because `accent-type` runs on the
keystroke's critical path — a `cat` is free, a `qs ipc` round-trip is not.

Persisting across restarts falls out of this for free.

### New pieces

| File | Role |
|---|---|
| `components/services/AccentCtl.qml` | language state, panel state, variant table, timeout |
| `components/services/AccentIpc.qml` | `IpcHandler { target: "accent" }` → `show(base)`, `select(i)`, `hide()` |
| `components/widgets/AccentPanel.qml` | display-only `PanelWindow`, **no keyboard focus** |
| `~/.config/hypr/scripts/accent-type` | types the default, opens the submap |
| `~/.config/hypr/scripts/accent-cycle` | backspace + retype + notify |
| `~/.config/hypr/scripts/accent-commit` | exit submap, hide panel |
| `~/.config/quickshell/accents.json` | the table |

`~/.config/hypr/scripts/accent-pick` is **deleted**, and the `MOD5` binds in
`conf.d/20-binds.conf:228-240` repointed at `accent-type`.

The panel appears **next to the island** (bottom-left), not screen-centred. It is
feedback on a character you already typed, not a modal chooser, and the existing
centred-popup trade-off documented in `~/nixos-config/MEMORY.md` doesn't apply —
nothing here needs to be caret-anchored.

### Phase 2 done when

In `pt`, AltGr+a types `ã` instantly; pressing Right once replaces it with `á` and the
panel's bubble moves; typing a letter continues normally with no stray keypresses; and
walking away for two seconds leaves no submap stuck on.

---

## Why not do accents inside kanata

Kanata *can* do this: `(unicode ã)` works on Linux, and a chain of generated layers
(`acc-a-0` → Right → `(macro bspc (unicode á) (layer-switch acc-a-1))` → …) would give
the type-then-refine behaviour with no compositor involvement and no `wtype`.

Rejected as the primary path because:

- **Mode and language are orthogonal.** Kanata has one active layer. Supporting
  3 modes × 3 languages means a layer product, and every new language or mode multiplies
  it. The Hyprland-submap design keeps language as plain data in a JSON file.
- The variant chain is one generated layer per (language, letter, variant) — hundreds of
  layers in a file that is currently hand-written and readable.
- `wtype` is already proven in this exact role by `accent-pick`.

Worth revisiting only if the submap approach turns out to have an unfixable input-timing
problem. Keep the finding that it's possible.

---

## Why the daemon wasn't tested against real kanata

The daemon (Phase 1 step 2) was exercised against a **mock TCP server** built from
kanata's own wire shapes, not the real `kanata-internal` service, because the
live-running system kanata predates the `port` module change (it's a long-running
process from before this session's edits, so it has no TCP server open yet), and
spinning up a *second*, scratch kanata process to test against requires opening
`/dev/uinput`, which `aj` has no permission for outside the systemd service's
`SupplementaryGroups = [ input uinput ]` (confirmed: a manual `kanata --port ...` run
as `aj` fails with `Failed to open the output uinput device: Permission denied`, before
the TCP listener ever starts). Granting `aj` the `uinput` group directly, or running a
throwaway kanata as root, are both real system-security changes bigger than what a
protocol smoke-test justifies — so the daemon's *logic* was verified precisely (mock
server built straight from `tcp_protocol/src/lib.rs`), while the *real-system*
end-to-end check is deferred to `nixos-rebuild switch` + restarting the real
`kanata-internal` service, which is the next step and does need your go-ahead since it
restarts the keyboard remapper. Real-kanata confirmation still needed: that the
build's `--port` flag is accepted (confirmed — `kanata --help` lists `-p/--port`,
version is unanimous across the flag and the running binary), and that the running
service actually opens 7979 after switch (not yet observed).

## Open items

- Decide whether `MessagePush`-based launcher mode (option 1 above) supersedes the
  nixos-config ROADMAP's `cmd`-based launcher plan. It almost certainly should —
  that item needs rewriting either way, since `cmd` is compiled out.
- The `aj` / `default` multi-profile switcher from the original ROADMAP entry (a
  down-arrow below the mode letters) is **deferred**. It is a third axis of state on an
  island that now has two, and `kanata-default.kbd` does not exist yet. Revisit after
  Phase 2.
- Framework-13 gets the same `services.kanata.keyboards.internal.port = 7979` for free
  (shared module) — confirmed its `.kbd` has the identical five layer names as the
  ThinkPad's, so one mode table serves both hosts without a per-host branch.

## Relevant files

- `rices/limerence/components/frame/LeftBar.qml` — host; island anchors above `PowerIcon`
- `rices/limerence/components/widgets/BubbleItem.qml` — pill chrome, reused as-is
- `rices/limerence/components/widgets/DotTrack.qml` — sliding-selection reference
- `rices/limerence/components/services/ObsCtl.qml` — daemon + `SplitParser` reference
- `rices/limerence/components/services/NotifsIpc.qml` — `IpcHandler` reference
- `rices/limerence/config/Appearance.qml` — per-mode colour tokens
- `~/nixos-config/hosts/{thinkpad-t14,framework-13}/kanata/kanata-internal.kbd`
- `~/nixos-config/modules/kanata.nix`
- `~/.config/hypr/conf.d/20-binds.conf` — `MOD5` binds, new `accent` submap
