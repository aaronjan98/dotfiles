# ROADMAP.md — Quickshell

This file tracks deferred bugs and future feature work for the Quickshell shell configuration.

---

## Architectural foundations
Things to build correctly from the start to avoid refactoring later as features are added.

### 1. Fix the popup pattern before adding more popups
The escape key bug (missing `WlrLayershell.keyboardFocus`) and the cursor/click-to-close inconsistency affect existing popups and will affect every future popup if not fixed first. Establish a single correct popup template (scrim + PanelWindow + keyboardFocus + Escape handler + PointingHandCursor on icon) and make all future popups follow it.

### 2. Build `EffectsState.qml` before any shader feature
Every shader feature (music visualizer, ripple, chasers, wallpaper scenes, effects panel) needs runtime-writable configuration that persists across sessions. Build this singleton first with JSON read/write on startup/change. Adding it retroactively means touching every shader feature again.

### 3. Use Hyprland IPC socket — never `hyprctl` subprocesses in hot paths
`Quickshell.Hyprland` maintains a persistent IPC connection. Use it for all Hyprland data (cursor position, focused client, workspace state). Spawning `hyprctl` in a timer or animation loop forks a process per tick — at 60fps that is ~1–2% CPU overhead for what should cost ~0%.
Applies to: wallpaper cursor tracking, window chaser position, any future polling of Hyprland state.

### 4. Extract shared shader utilities before writing multiple shaders
The `smoothstep` edge-fade curve is needed by both the music visualizer and the network visualizer. The `time` and `resolution` uniforms are needed by every shader. Create a `shaders/utils.glsl` include (or a documented uniform convention) before writing the second shader, not after.

### 5. Wrap bar content in `layer.enabled` once, not per-feature
The music visualizer ripple and potentially the chaser effects both need the top bar rendered to an offscreen texture (`layer.enabled: true` + `layer.effect: ShaderEffect`). This can only be set once per Item. Decide upfront which Item gets `layer.enabled` and what the `layer.effect` composition order is — doing this per-feature leads to conflicting layer wrappers that can't be stacked without restructuring.

### 6. Fix the frame corner gap before implementing the theme switcher
A light-coloured `frameBg` makes the triangular corner gaps visible. The theme switcher is useless for light wallpapers until this is resolved. Fix the geometry first (`QML Shape` or `OpacityMask` approach), then wire matugen palette output to `Appearance.qml`.

### 7. Pause cava when silent — implement from the start
The cava process costs ~1–2% CPU when processing audio. Build the pause/resume logic (silence detection → stop process, audio activity → restart) into `AudioVisualizer.qml` from the beginning rather than adding it as a power-saving fix later.

### 8. Appearance panel is infrastructure, not a feature
The appearance/effects panel (`AppearancePopup.qml`) controls all other visual features. Build at least the skeleton of it — with `EffectsState.qml` bindings and the JSON persistence — before implementing the individual effects it will control, so each effect can be toggled and tuned without editing code.

---

## Performance budget (idle CPU target: ≤5%)

| Component | CPU impact | GPU impact | Notes |
|---|---|---|---|
| Existing Quickshell | ~0.5–1% | negligible | baseline |
| Network stats poll (500ms) | <0.1% | — | file read only |
| Kanata TCP socket | ~0% | — | event-driven |
| Battery health poll | ~0% | — | only on popup open |
| cava (audio playing) | ~1–2% | — | pause when silent → 0% |
| cava (silent/paused) | ~0% | — | |
| cursorpos via IPC | ~0.1% | — | ⚠ ~1–2% if using hyprctl subprocess |
| Chaser shaders | ~0% | light | GPU-only; CPU drives only a single float animation |
| Network visualizer (Canvas) | ~0.2% | — | Canvas redraws at 60fps |
| Music visualizer shader | ~0% | light–moderate | GPU-only after cava feeds the array |
| Generative wallpaper (simple) | ~0.1% | light | noise/snow shader |
| Generative wallpaper (fluid) | ~0.3% | moderate–heavy | GPU; may need resolution scaling; disable on battery |
| **Total (all features, audio playing)** | **~2–4%** | moderate | within 5% target |
| **Total (all features, silent)** | **~1–2%** | light–moderate | comfortably within target |

---

## Ongoing issues

### Domain dot click: wrong slot restored after keyboard navigation
Status: confirmed

Symptom:
- Clicking a domain bubble in the left bar navigates to the correct domain but lands on the wrong slot — usually slot 1 — instead of the last slot visited in that domain
- Only reproduces after using keyboard navigation for a while; works correctly at first
- Pure keyboard navigation is unaffected

Two interacting root causes:

**1. LeftBar click doesn't save the current slot before leaving**
The `onClicked` handler in `LeftBar.qml` reads `DomainMemory.lastSlot(targetDom)` and dispatches directly, but never calls `DomainMemory.setLastSlot(currentDom, currentSlot)` for the domain being left.
Compare: `ws-domain`, `ws-rel`, and `ws-slot` all write the current position to `last.txt` *before* navigating.
This means clicking away mid-slot can leave the departing domain's entry stale.

Fix: add `S.DomainMemory.setLastSlot(root.domain, root.slot)` at the top of the `onClicked` handler in `LeftBar.qml` before reading the target slot.

**2. Atomic `mv` in bash scripts breaks `FileView`'s inotify watch**
`ws-domain`, `ws-rel`, and `ws-slot` all write state with:
```bash
awk ... "$last_file" > "$tmp" && mv "$tmp" "$last_file"
```
`mv` replaces the file with a new inode. Quickshell's `FileView { watchChanges: true }` attaches its inotify watch to the original inode. After the first keyboard navigation the watch silently detaches; subsequent script writes go undetected by `DomainMemory`. `lastSlot()` returns whatever it last successfully read — often 1 for domains not yet visited — explaining why the bug only appears after using the keyboard for a while.

Fix (two options, apply both):
- In `DomainMemory.qml`: call `lastView.reload()` (or equivalent) inside `lastSlot()` before parsing, so each click forces a fresh read regardless of watch state
- In the bash scripts: replace `mv "$tmp" "$last_file"` with `cat "$tmp" > "$last_file" && rm "$tmp"` to write in-place (same inode, inotify stays attached)

Relevant files:
- `rices/limerence/components/frame/LeftBar.qml` — missing `setLastSlot` before dispatch (line ~137)
- `rices/limerence/components/state/DomainMemory.qml` — `lastSlot()` and `_lastText()` may use stale cache
- `~/.config/hypr/scripts/ws-domain`, `ws-rel`, `ws-slot` — all use `mv` for atomic write

### Nix icon: spin on hover, freeze at current angle on unhover
Status: fun / low priority

- While cursor is over the CornerPatch Nix icon, the snowflake rotates continuously
- When cursor leaves, rotation stops immediately at whatever angle it's currently at (no snap-back to 0)
- When cursor re-enters, rotation resumes from the frozen angle — no jump or restart

Implementation note:
- A `NumberAnimation` with `loops: Animation.Infinite` stops at the current value when `running` is set to false, but restarts from `from` when set to true again — which would cause a jump
- Correct approach: on each hover-start, set `from: nix.rotation` and `to: nix.rotation + 360`, then start the animation; this ensures it always continues from the current angle
- Or: a `Timer` at 60fps that increments `rotation` by a fixed delta per tick while `containsMouse` is true — simpler and more robust

Relevant file: `rices/limerence/components/frame/CornerPatch.qml`

### Battery health popup: charge limit toggle + power mode switcher
Goal:
- Clicking the battery icon in the top-right pill opens a popup combining two battery-related controls:
  1. **Charge limit toggle**: cap charging at 80% (similar to AlDente on macOS); shows current percentage, current limit, and a toggle to enable/disable the cap
  2. **Power mode switcher**: select between performance profiles (e.g. power-saver, balanced, performance) — similar to what GNOME Power Profiles exposes; shows current mode and lets you switch

Two parts — Quickshell UI and NixOS backend (see `~/nixos-config/docs/ROADMAP.md` for the system side):
- The popup follows the existing popup pattern (scrim + PanelWindow, Escape to close)
- A Quickshell service reads the current threshold from sysfs and writes changes via a privileged helper (polkit action or setuid wrapper)
- Power mode reads/writes via `power-profiles-daemon` DBus API or the sysfs `energy_performance_preference` node (ThinkPad specific: `/sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference`)

Relevant files:
- `rices/limerence/components/widgets/BatteryIcon.qml` — add `onClicked` signal
- New: `rices/limerence/components/widgets/BatteryPopup.qml`
- New: `rices/limerence/components/services/BatteryHealth.qml` (reads/writes charge threshold)
- New: `rices/limerence/components/services/PowerProfile.qml` (reads/writes power mode)
- `rices/limerence/components/frame/TopBar.qml` — wire up popup open state (same pattern as wifiPopupOpen etc.)

### Volume icon: headphones not shown for Bluetooth audio devices
Status: confirmed

- Plugging in headphones via aux (3.5mm) correctly switches the volume icon to a headphones icon
- Connecting Bluetooth headphones does not trigger the same icon change — the default speaker icon remains
- Expected: any headphone/headset device (wired or Bluetooth) should show the headphones icon

Root cause is likely in how the audio source/sink is detected — the aux path probably checks PipeWire/PulseAudio port description or device form factor, while Bluetooth sinks report a different form factor or node name that the icon logic doesn't handle

Relevant file: wherever the volume icon and its device-type detection live in the Quickshell audio service (likely a service that queries PipeWire sinks)

### Escape key does not close power or notification popups
Status: confirmed

- **PowerPopup**: has `Keys.onEscapePressed: requestClose()` (line 49) but no `WlrLayershell.keyboardFocus` set — the window never receives keyboard input so the handler never fires. Fix: add `WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None` (matching how Wifi/Brightness popups handle it).
- **NotificationCenter**: is a plain `Rectangle`, not a `PanelWindow` — has no escape handler and no keyboard focus wiring at all. Fix requires either adding escape handling to the host PanelWindow that embeds it, or converting to the same popup pattern used by Wifi/Brightness/Power.

Relevant files:
- `rices/limerence/components/widgets/PowerPopup.qml` — missing `WlrLayershell.keyboardFocus`
- `rices/limerence/components/widgets/NotificationCenter.qml` — no escape handling
- `rices/limerence/components/widgets/NotificationIcon.qml` — likely the host that embeds NotificationCenter; check if keyboard focus can be wired there

### Top-right island: inconsistent cursor and click-to-close behavior across icons
Status: confirmed

Problem:
- Icons that have `cursorShape: Qt.PointingHandCursor` (Wifi, Brightness, Bluetooth) lose the hand cursor once their popup is open — the cursor reverts to the default arrow
- Closing the popup on those same icons requires a slight cursor nudge to a different position rather than clicking the icon in place; clicking the exact same spot does not register
- `NotificationIcon` has no `cursorShape` set at all, so hovering it never shows a hand — minor inconsistency, though its open/close toggle works correctly

Working reference: `PowerIcon.qml` handles all of this correctly — cursor stays as hand while popup is open, and clicking the icon again closes the popup cleanly from the same position.

Relevant files:
- `rices/limerence/components/widgets/PowerIcon.qml` — working reference
- `rices/limerence/components/widgets/WifiIcon.qml` — affected
- `rices/limerence/components/widgets/BrightnessIcon.qml` — affected
- `rices/limerence/components/widgets/BluetoothIcon.qml` — affected
- `rices/limerence/components/widgets/NotificationIcon.qml` — missing cursorShape

### Theme switcher: frame corner gaps visible on light wallpapers
Status: confirmed (dark wallpapers only work today)

Problem:
- The ContentFrame draws its background as 4 rectangular strips around the content hole. The inner edge of the hole uses `frameRadius` rounded corners (via the inner glow Rectangles), creating a visual rounded join between frame and content area.
- At each inner corner the rectangular strip geometry and the visual rounded corner leave a small triangular/wedge region that isn't covered by the frame background color. On dark wallpapers this is invisible. On light wallpapers (or any wallpaper-derived color that contrasts with the wallpaper itself) the gap is obvious — the wallpaper bleeds through.
- This is the reason only dark wallpapers work with the current setup: a light `frameBg` derived from a light wallpaper would expose the corner gaps.

Soramane's approach: patch corners with small extra Rectangles (works but is geometry-fragile).

Better paths to investigate:
- **QML `Shape` + `PathFigure`**: draw the entire frame ring (outer rect minus inner rounded rect) as a single filled shape — no gaps, no patches, one paint call
- **`layer.enabled` + `OpacityMask`**: render the strips to an offscreen layer and mask them against a rounded-corner shape
- Confirm whether soramane's shader approach solves this or only handles animation effects

Goal of the theme switcher (context):
- Auto-derive palette from active wallpaper at runtime via `matugen`
- Apply derived colors to `frameBg`, `bubbleBg`, `borderCol`, glow colors, etc. in `Appearance.qml`
- Must work for both dark and light wallpapers

Relevant files:
- `rices/limerence/components/frame/ContentFrame.qml` — 4-strip geometry, inner glow radius
- `rices/limerence/config/Appearance.qml` — `frameBg`, `frameRadius`, all palette values

### Brightness sliders: out of sync when adjusted via hardware keys
Status: confirmed

- The brightness popup (screen and keyboard backlight sliders) does not reflect hardware-key changes made while the popup is closed
- If you press the brightness keys before opening the popup, the slider handle appears at the last position the popup knew about, not the actual current brightness
- Reproduces every time: adjust brightness via keyboard, then open the popup — slider is visually wrong until you move it

Root cause is likely that the backing service (`BrightnessCtl.qml` or equivalent) only reads the current value at startup or on popup open, rather than watching for changes via inotify/DBus. Hardware keys update the actual sysfs/DBus value but don't push an update back to the QML property, so the UI drifts.

Fix: watch the brightness sysfs node (or DBus signal) continuously so the service property stays in sync regardless of how the brightness was changed.

Relevant files:
- `rices/limerence/components/services/BrightnessCtl.qml` — backing service; needs live sysfs watch or DBus subscription
- `rices/limerence/components/widgets/BrightnessPopup.qml` — slider binds to service property

### Night light slider: no live preview during drag, and flash to white on commit
Status: confirmed

Two related bugs in the brightness popup's night light section:

**1. Temperature only updates on release, not while dragging**
`GammaCtl.preview()` updates `tempPercent` in the UI but never calls hyprsunset — so the actual display colour doesn't change while sliding. `commit()` on release calls `start()` for the first time. This was intentional to avoid flashing during drag, but the result is that the slider gives no live feedback.

**2. Flash of white/blue on every commit**
`start()` always calls `stop()` first (pkill hyprsunset), then waits 40ms before launching a new process. During that gap the display reverts to its native unfiltered colour (bright white). This flash is visible every time the slider is released or the toggle is turned on.
The toggle bug is compounded by `tempPercent` initialising to `0` (= 6500 K, neutral white), so if the last-used value isn't persisted, enabling the toggle starts from cold before snapping to the intended warmth.

Relevant files:
- `rices/limerence/components/services/GammaCtl.qml` — `preview()`, `commit()`, `start()`, `stop()`, `startDelay`
- `rices/limerence/components/widgets/BrightnessPopup.qml` — slider wiring (`onValueChangedLive`, `onValueCommitted`)

---

## Future features

### Layout system: `Layout.qml` singleton for multiple shell profiles

Rather than scattering per-layout conditionals throughout individual components, introduce a `Layout.qml` singleton (same pattern as `Appearance.qml`) that exposes structural layout properties. Each component binds to these properties instead of hardcoded anchors or `isExternal` flags.

Example shape:
```qml
pragma Singleton
QtObject {
  property string profile: "laptop"   // "laptop" | "external" | "right-bar"

  property bool   showLeftBar:   profile === "laptop" || profile === "right-bar"
  property bool   showRightBar:  profile === "right-bar"
  property bool   showCorner:    profile === "laptop"
  property string vertBarSide:   profile === "right-bar" ? "right" : "left"
  property int    topBarHeight:  profile === "external" ? C.Appearance.topHExternal : C.Appearance.topH
  property int    topBarMarginLeft:  showLeftBar && vertBarSide === "left"  ? C.Appearance.leftW : 0
  property int    topBarMarginRight: showRightBar && vertBarSide === "right" ? C.Appearance.leftW : 0
}
```

The active profile would be driven by `Quickshell.screens` context (laptop screen vs external) or by a runtime-writable property for manual switching.

**Design constraint**: components are not expected to change orientation (e.g., a vertical domain dot column stays vertical on the right bar — it doesn't reflow to horizontal). The `Layout.qml` system controls *which* bars are shown and *where* they are anchored, not the internal layout direction of islands within them.

**Planned profiles:**

1. **`laptop`** (current layout) — left vertical bar, standard top bar height, CornerPatch visible
2. **`external`** — no vertical bar, no CornerPatch, taller top bar, top bar spans full width
3. **`right-bar`** — vertical bar moved to right side, same islands, top bar spans full width on left

Profile 2 (external) is the first to implement; the `isExternal` flag in the near-term implementation is a stepping stone toward this singleton.

Relevant files once implemented:
- New: `rices/limerence/config/Layout.qml` — profile singleton
- `rices/limerence/components/frame/FrameRoot.qml` — drive bar visibility from `Layout`
- `rices/limerence/components/frame/TopBar.qml` — margins and height from `Layout`
- `rices/limerence/components/frame/LeftBar.qml` — anchor side from `Layout`
- `rices/limerence/components/frame/ContentFrame.qml` — hole margins from `Layout`

### Top-right pill: calendar icon and unified event popup
Goal:
- Add a calendar icon immediately before the date text in the right pill (between a new divider and `W.Clock`), matching the same icon-before-text pattern used elsewhere in the pill
- Clicking the icon opens a popup showing unified calendar events from all sources: Calendly, Obsidian daily notes/tasks, and any other calendar feeds

Popup contents (planned):
- A scrollable day/week view of upcoming events
- Each event shows source label (Calendly / Obsidian / etc.), title, time, and optional description
- Today's events at the top; later entries below with a subtle date separator

Data sources to integrate:
- **Calendly**: poll via Calendly API (REST, requires API token); fetch scheduled events for the authenticated user
- **Obsidian**: parse the daily note for the current day (or a `tasks.md` / dataview query output) to extract TODO/event lines — Obsidian has no live API, so this is a file read from the vault directory
- **Other feeds**: iCal/`.ics` files or CalDAV if additional sources are added later (e.g. a self-hosted calendar)

Implementation notes:
- A `CalendarService.qml` singleton polls each source on a configurable interval and merges events into a unified list sorted by time
- Calendly polling should be infrequent (e.g. every 5 minutes) to avoid rate limits; Obsidian file watch can use `inotify` via a Quickshell `FileView` for near-instant updates
- API token stored outside the QML source (e.g. read from `~/.config/quickshell/secrets.json` or a `$CALENDLY_TOKEN` env var at startup)
- Popup follows the existing popup pattern (scrim + PanelWindow, Escape to close), same width as the wider popups (`popupWidthWide`)

Placement in TopBar:
```qml
// Inside the right Pill Row, just before W.Clock:
Rectangle { width: C.Appearance.dividerW; height: C.Appearance.dividerH; color: Qt.rgba(1,1,1,0.18) }
W.CalendarIcon { onClicked: root.calPopupOpen = !root.calPopupOpen }
```

Relevant files:
- `rices/limerence/components/frame/TopBar.qml` — add `calPopupOpen` state and wire up popup; insert `CalendarIcon` before `Clock` in the right pill Row
- `rices/limerence/components/widgets/Clock.qml` — no change needed
- New: `rices/limerence/components/widgets/CalendarIcon.qml`
- New: `rices/limerence/components/widgets/CalendarPopup.qml`
- New: `rices/limerence/components/services/CalendarService.qml`

### Left bar: Kanata mode indicator island
Goal:
- Add a pill-shaped island between the NixOS favicon (CornerPatch) and the vertical workspace island
- Displays the current Kanata layer as a vertically-stacked set of mode letters with a sliding bubble indicator over the active one
- The entire island changes color per mode for at-a-glance identification without reading the letter
- Island is interactive: clicking a letter switches Kanata to that mode (bidirectional, not read-only)

Mode letters (top to bottom):
- **N** — Normal (default layer)
- **C** — CapsLock layer
- **M** — Major layer
- **L** — Launcher mode (not yet implemented in Kanata — see nixos-config ROADMAP)
- Additional modes (e.g. script-execution mode) to be added as they are implemented

Profile switcher:
- A down-arrow button below the mode letters
- Tapping it expands an inline list of available Kanata profiles (separate `.kbd` files; currently planned: `aj`, `default`)
- Clicking a profile in the list switches to it and collapses the list; tapping the arrow again also cycles and collapses

Communication with Kanata:
- Requires Kanata TCP server (`tcp-port` in `defcfg`) for bidirectional control — receiving layer-change events AND sending switch-layer/switch-profile commands
- Preferred implementation: a Quickshell `Process` or `Socket` service that connects to the Kanata TCP socket, parses layer-change messages, and sends commands on user interaction
- See nixos-config ROADMAP for the required Kanata config changes (TCP port, launcher layer, profile files)

Relevant files:
- `rices/limerence/components/frame/LeftBar.qml` — host; island goes between CornerPatch gap and workspace BubbleItem
- `rices/limerence/config/Appearance.qml` — add per-mode color tokens

### Left bar: app launcher dock between workspace island and power button
Goal:
- Fill the empty vertical space between the domain workspace island and the power button with pinned app icons for frequently used apps
- Clicking an icon launches the app (or focuses it if already open)
- Each icon shows a notification badge when that app has pending notifications

Notes:
- The left bar (`LeftBar.qml`) already has the workspace `BubbleItem` centered and the `PowerIcon` anchored to the bottom — the middle space is currently empty
- App list should be user-configurable (pinned list, not auto-generated)
- Notification badge data comes from `Notifs.qml` (already available as a service); matching notifications to apps requires matching by `appName`/`appId`

Relevant files:
- `rices/limerence/components/frame/LeftBar.qml`
- `rices/limerence/components/services/Notifs.qml`

### Workspace pills: notification badges on inactive pills
Goal:
- Show a small badge on inactive workspace pills when any window in that workspace has a pending notification, so it's clear which workspace needs attention without switching to it

Notes:
- Notification data already available via `Notifs.qml`; matching to a workspace requires knowing which app/toplevel is in which workspace (via `Hyprland.toplevels`)
- Badge should be visually subtle on inactive pills and suppressed on the active pill (since you're already there)

Relevant files:
- `rices/limerence/components/widgets/DotTrack.qml`
- `rices/limerence/components/services/Notifs.qml`
- `rices/limerence/components/frame/TopBar.qml`

### Top bar: network activity history visualizer
Goal:
- Fill the empty horizontal space between the centered workspace island and the right-side pill (wifi/clock/etc.) with a real-time scrolling network speed graph
- Shows both upload and download speeds simultaneously as a history — not just the current value but a rolling window of recent activity, similar to JDownloader's per-package speed graph
- Visually distinct lines or areas for upload vs. download (e.g. two colours, or mirrored above/below a centre axis)

Data source:
- Poll `/proc/net/dev` on a timer (e.g. every 500ms) via a Quickshell `FileView` or lightweight `Process`
- Compute delta bytes between polls to get bytes/second for the active interface (detect active interface by largest traffic or by reading the default route from `/proc/net/route`)
- Maintain a rolling array of (upload_bps, download_bps) samples sized to the widget width in pixels — one sample per pixel column gives a natural scrolling effect

Rendering:
- `Canvas` item (QML JavaScript draw calls) or a `ShaderEffect` for the scrolling graph
- Each frame: shift the history array left by one, push the new sample, redraw
- Scale dynamically: the y-axis maximum adjusts to the peak value in the current history window (with a smooth ease-out so the scale doesn't jump)
- Options for visual style (configurable via the appearance/effects panel):
  - **Lines**: simple polyline for upload and download
  - **Area**: filled area chart (semi-transparent fill under the line)
  - **Mirrored**: download drawn upward, upload drawn downward from a centre baseline
- Edge fade: apply the same `smoothstep` edge falloff used by the music visualizer so the graph tapers to transparent at left and right edges, sitting seamlessly in the bar

Labels:
- Optional small text overlays showing current speed (e.g. "↓ 2.4 MB/s  ↑ 180 KB/s") rendered at low opacity so they don't dominate the visual

Implementation notes:
- The rolling array and polling logic is straightforward — simpler data pipeline than the music visualizer (no external process needed beyond a file read)
- Consider sharing the `smoothstep` edge-fade logic with the music visualizer as a reusable shader snippet
- Width available depends on the centered workspace island width (which is dynamic) — the visualizer should flex with the remaining space

Relevant files:
- `rices/limerence/components/frame/TopBar.qml` — host; visualizer goes between workspace BubbleItem and right Pill
- New service: `rices/limerence/components/services/NetworkStats.qml`
- New widget: `rices/limerence/components/widgets/NetworkVisualizer.qml`

### Top bar: music visualizer with shader-driven ripple spread across bars
Goal:
- Fill the empty horizontal space in the top bar between the left stats pill (CPU/MEM) and the centered workspace island with a real-time music visualizer
- The visualizer reacts to audio and supports multiple selectable patterns (bars, wave, etc.)
- The visualization should appear seamless — amplitude fades to zero at both edges so the effect looks contained within the gap rather than clipped
- A GLSL shader effect propagates the visualizer's energy outward as subtle distortion ripples across the rest of the top bar and optionally the left bar, as if the vibration is contagious

**Audio data pipeline:**
- Source: PipeWire/PulseAudio output captured by `cava` running in FIFO/raw mode, which outputs a stream of frequency bar amplitudes
- Quickshell `Process` reads cava's stdout continuously and parses it into a frequency amplitude array (e.g. 32–64 bars)
- The array is exposed as a QML property and updated each frame, then passed to the visualizer and the shader as uniforms
- **cava lifecycle**: pause/stop the cava process when no audio is playing (detect via PipeWire sink activity or silence threshold) and restart on audio activity — cava costs ~1–2% CPU when actively processing; idling it to zero when silent is worth doing from the start

**Visualizer rendering (in the gap):**
- Rendered as a `ShaderEffect` item anchored to fill the available gap space
- Patterns (switchable at runtime, stored in config or toggled via a click):
  - **Bars**: vertical frequency bars, symmetric or mirrored
  - **Wave**: smooth waveform interpolated from frequency data
  - Potentially more (circular, particle, mirrored spectrum)
- Edge seamlessness: the GLSL fragment shader multiplies amplitude by a smooth falloff curve (e.g. `smoothstep`) near the left and right edges so the visualization tapers to zero naturally

**Shader ripple spread (the "contagious" effect):**
- The top bar content (and optionally the left bar) is rendered to an offscreen texture via `layer.enabled: true` + `layer.effect: ShaderEffect`
- A fragment shader distorts that texture using a ripple/wave displacement function driven by the current audio amplitude and a time uniform
- At low amplitude (quiet audio): no visible distortion
- At high amplitude: subtle UV coordinate warping makes the bar content appear to breathe or vibrate in sync with the music
- The distortion magnitude falls off with distance from the visualizer (stronger near the center gap, subtler at the far ends of the bars)
- The shader needs: `sampler2D source` (the bar texture), `float time`, `float amplitude` (peak or RMS from the frequency array), `vec2 resolution`

**Implementation path:**
1. Wire cava as a persistent `Process` singleton service (similar to `GammaCtl.qml` / `BrightnessCtl.qml` pattern)
2. Build the visualizer `ShaderEffect` item with a switchable pattern uniform
3. Wrap the TopBar (and optionally LeftBar) content with `layer.enabled` and apply the ripple `ShaderEffect` as `layer.effect`
4. Pass amplitude data through as a uniform; tune distortion scale so it's ambient rather than distracting

**Open questions for implementation:**
- cava output format to use (raw binary vs. ASCII bars mode — raw is more efficient for high frame rates)
- Whether the ripple applies to the left bar as well or only the top bar
- Frame rate cap for the shader (sync to display refresh or throttle to reduce GPU load)
- Whether pattern selection is exposed in the UI (e.g. clicking the visualizer area cycles patterns)

Relevant files:
- `rices/limerence/components/frame/TopBar.qml` — host for the visualizer item and layer.effect
- `rices/limerence/components/frame/LeftBar.qml` — optional ripple target
- New service: `rices/limerence/components/services/AudioVisualizer.qml` (cava process + frequency array)
- New widget: `rices/limerence/components/widgets/MusicVisualizer.qml`

### Workspace pills: app icons + expand-to-show-all behavior
Goal:
- Replace the current dot/bubble workspace indicators with actual app icons so workspaces are visually identifiable
- **Inactive pill**: small, shows a single representative icon (most recent or primary app in that workspace), even if multiple windows are open
- **Active pill**: expands (as now) AND grows larger, revealing all app icons for every window in that workspace
- **On switch**: the departing pill collapses to one icon and shrinks; the arriving pill expands and fans out all its icons

Implementation notes:
- Workspace and toplevel data already available via `Hyprland.toplevels` in `TopBar.qml` (`wsList`, `toplevelCountForWorkspaceId`)
- The main non-trivial piece: resolving a per-toplevel app icon from `appId`/`class` against the system icon theme
- The existing pill expand/shrink animation in `DotTrack` is the right foundation — extend it rather than replace it
- No shader needed; pure QML animation is sufficient

Relevant files:
- `rices/limerence/components/widgets/DotTrack.qml`
- `rices/limerence/components/frame/TopBar.qml`
- `rices/limerence/components/frame/LeftBar.qml`

### Generative art wallpaper system with cursor reactivity
Goal:
- Replace static/gif wallpapers with GPU-rendered generative art shaders running as a live Quickshell background
- Wallpapers animate continuously and react to cursor position in real time
- Multiple wallpaper "scenes" selectable from the appearance/effects panel (fluid/gas sim, particle attraction, snow, etc.)

Feasibility summary:
- **Fully feasible** on the current setup (Hyprland + Quickshell + AMD iGPU on ThinkPad T14)
- Simple animations (snow, noise fields, cellular automata): straightforward `ShaderEffect` at `WlrLayer.Background`
- Cursor-reactive scenes: feasible via Hyprland IPC socket (via `Quickshell.Hyprland`) — Wayland does not deliver pointer events to the background layer while windows are focused above it, so cursor position is read from Hyprland IPC at up to 60fps and passed as a shader uniform (~16ms latency, imperceptible for fluid/attraction effects). Do NOT use `hyprctl cursorpos` subprocess for this — see architectural notes.
- Multi-pass simulations (fluid where frame N reads from frame N-1): possible via QML `layer.enabled` ping-pong rendering, more complex to set up but achievable

Architecture:
- Quickshell `PanelWindow` at `WlrLayer.Background` with a `ShaderEffect` as the full-screen root item
- A `WallpaperService.qml` singleton manages:
  - Current scene selection (shader source or enum)
  - Cursor position: **use Hyprland IPC socket directly via `Quickshell.Hyprland`**, NOT `hyprctl cursorpos` subprocess — spawning `hyprctl` 60 times per second generates ~60 process forks/sec which costs ~1–2% CPU on its own; the IPC socket approach drops this to ~0.1%
  - Shared time uniform (elapsed seconds, for animation)
  - Cursor position uniform
- Each scene is a self-contained GLSL fragment shader receiving: `vec2 resolution`, `vec2 cursor`, `float time`, and scene-specific uniforms
- Scene switching: swap the active shader at runtime via the appearance/effects panel (no restart needed if shaders are loaded dynamically)

Planned scenes (non-exhaustive):
- **Fluid/gas**: cursor acts as a force emitter pushing the fluid field outward; colours blend and advect
- **Particle attraction**: floating particles drift toward cursor; speed and cluster density scale with proximity
- **Reaction-diffusion**: Turing-pattern simulation; cursor seeds disturbances in the pattern
- **Snow / falling particles**: ambient animation, no cursor interaction; speed/density configurable
- **Noise field**: Perlin or simplex noise animating slowly; calm, low-GPU-cost option

Performance notes:
- Simple scenes (snow, noise): negligible GPU load
- Fluid/particle sims at 1080p/60fps: comfortable on AMD iGPU for moderate complexity
- Multi-pass fluid: more GPU pressure; may need resolution scaling (render at 50% and upscale) if frame drops occur
- Shader should be pausable/disabled from the effects panel to save power when on battery

Integration with theme switcher:
- The wallpaper scene is part of the appearance state (`EffectsState.qml`)
- `matugen`-derived palette colours can be passed as uniforms so the wallpaper palette adapts to the active theme
- Replaces `swww` entirely for animated scenes; `swww` can remain as a fallback for static image wallpapers

Relevant files:
- New: `rices/limerence/components/frame/WallpaperWindow.qml` (Background-layer PanelWindow)
- New: `rices/limerence/components/services/WallpaperService.qml`
- New: `rices/limerence/shaders/` directory for scene GLSL files
- `rices/limerence/components/state/EffectsState.qml` — scene selection state

### Appearance & effects control panel
Goal:
- A unified popup/panel for everything visual: theme switching, shader effect toggles, and per-effect configuration
- Accessible from the top bar (new icon, or grouped with existing brightness/notification area)
- Replaces the need to edit config files to tweak visual behavior at runtime

Sections the panel should cover:
- **Theme**: wallpaper picker + matugen-derived palette preview; apply button pushes new colors to `Appearance.qml` properties at runtime (see `~/.config/ROADMAP.md` → live theme switcher and the frame corner gap issue that must be solved first)
- **Chaser effects**: toggle on/off, speed, count, color/opacity, direction per chaser (frame vs. window)
- **Music visualizer**: pattern selector (bars, wave, etc.), sensitivity, edge falloff
- **Ripple/distortion**: toggle, max distortion amplitude, falloff distance from visualizer
- **Workspace pill animations**: toggle app icons, badge style
- Any future effects added to the shell

Implementation notes:
- All effect parameters should be runtime-writable properties on a singleton `EffectsState.qml` (similar to `GammaCtl.qml` pattern) so the panel just binds to those properties — no restarts needed
- Persistent settings across sessions: write to a JSON config file on change, read on startup
- Panel is its own `PanelWindow` popup following the same pattern as Wifi/Brightness popups (scrim + dismiss on Escape/click-outside)

Relevant files:
- New: `rices/limerence/components/state/EffectsState.qml`
- New: `rices/limerence/components/widgets/AppearancePopup.qml`
- `rices/limerence/config/Appearance.qml` — palette properties to make runtime-writable

### Chaser: light beam around the content frame border
Goal:
- One or more animated light beams ("chasers") that travel continuously around the visible border of the content frame
- Multiple chasers supported, each with configurable speed, color, length/falloff, and direction
- Clockwise by default; direction is configurable per chaser

Implementation:
- Rendered as a `ShaderEffect` layer on the `ContentFrame` (or a sibling `PanelWindow` at a higher layer)
- The chaser position is parametric: a single float `t` (0.0–1.0) animating via a `NumberAnimation` with `loops: Animation.Infinite` represents position around the perimeter
- The fragment shader maps `t` to a point on the rectangular path (top edge → right edge → bottom edge → left edge, with rounded corner compensation at the inner corners), then draws a gradient "comet" — bright head fading to transparent tail — centered on that point
- For multiple chasers: pass an array of phase-offset `t` values as uniforms, or run multiple shader instances stacked
- The path must follow the actual visual border shape including the rounded inner corners (`frameRadius`), not just the rectangular hull

Counter-clockwise variant (for window chaser contrast):
- Same shader, `t` decremented over time instead of incremented

Relevant files:
- `rices/limerence/components/frame/ContentFrame.qml` — attach chaser layer here
- New: shader file or inline GLSL in a new `ChaserEffect.qml` component

### Chaser: light beam around the focused Hyprland window
Goal:
- One or more chasers that travel around the border of the currently focused application window
- Runs counter-clockwise to contrast with the frame border chasers
- Multiple chasers possible (e.g. two going counter-clockwise with a phase offset)

Implementation notes:
- Requires knowing the focused window's position and size at all times — available via `Hyprland.focusedClient` (position, size, floating state)
- Rendered as a full-screen transparent `PanelWindow` at `WlrLayer.Overlay` with `mask: Region {}` (click-through), drawing only the chaser path over the window border
- The window border radius may differ per window (Hyprland `rounding` setting) — the chaser path should respect that
- The chaser must reposition instantly when focus changes and animate smoothly while the same window is focused
- When no window is focused (e.g. on an empty workspace), the chaser should fade out

Open question: whether to match Hyprland's own active border color or use a dedicated chaser color from `EffectsState`

Relevant files:
- New: `rices/limerence/components/frame/WindowChaser.qml` (full-screen overlay)
- `rices/limerence/components/frame/FrameRoot.qml` — register the overlay here

### Workspace switch: ripple effect
Goal:
- Play a ripple animation (expanding ring, fades out) centered on the active workspace pill when switching workspaces

Implementation notes:
- Doable with pure QML: a `SequentialAnimation` on a circle item (scale 0→2, opacity 1→0)
- A shader would only be warranted if the ripple needs to distort content underneath — a standard ripple ring does not

---

## How to use this file

- add deferred issues that are known but intentionally not fixed yet
- add feature ideas that should survive beyond a single chat session
- keep session-specific implementation details in `memory/` notes
