# OBS Control Redesign

## Goal

Make the top-bar OBS icon feel like a small recording controller and app handle,
not a miniature OBS Studio UI.

The user-facing workflow should be:

- launch or focus OBS from the top bar
- start, pause, and stop recording quickly
- choose a small set of recording presets
- toggle the expected audio/camera inputs
- open the full OBS window when detailed scene/source editing is needed

## Ownership

Primary owner: Quickshell `limerence`.

Related pieces:

- `components/widgets/ObsIcon.qml`
- `components/widgets/ObsPopup.qml`
- `components/services/ObsCtl.qml`
- `~/nixos-config/scripts/obs-ctl-daemon.py`
- `~/.config/hypr/scripts/obs-toggle` or equivalent helper

## Non-Goals

- Do not recreate full OBS Studio controls in the bar.
- Do not expose every scene, every source, or every advanced OBS output by default.
- Do not make the bar depend on knowing OBS internals beyond a small named contract.
- Do not treat OBS as a true headless daemon; the OBS GUI process remains the backend.

## Icon Behavior

The OBS icon is both status and window control.

Left click:

1. If OBS is not running, launch OBS.
2. If OBS is running but not focused, focus the existing OBS window. Prefer switching
   to the workspace where it already lives rather than pulling it into the current
   workspace.
3. If OBS is focused, hide it to `special:obs`.
4. If OBS is hidden on `special:obs`, show/focus it again.

The visual metaphor is "minimize to the bar", implemented through Hyprland special
workspace behavior. It does not need literal minimize animation into the icon.

Recording state should remain visible on the icon:

- disconnected / OBS unavailable: dim
- connected and idle: neutral
- recording: red / active
- paused: amber

## Dropdown Shape

The dropdown should be a recording control panel with these sections.

### Status

- OBS connection state
- recording timer
- disconnected action: `Launch OBS`
- connected action: `Open OBS` / `Hide OBS`

### Recording

- Start / Stop
- Pause / Resume

### Preset

Small set of user-facing modes mapped to OBS scenes:

- `Screen`
- `Screen + Camera`
- `Camera Only`

Optional later:

- `Region`
- `Window`

The UI should use these plain names even if the underlying OBS scene names differ.

### Inputs

Only show high-value toggles by default:

- Mic
- Desktop audio
- Camera

These map to named OBS inputs/sources. If an expected input is missing, show it as
unavailable rather than expanding into a raw source list.

### Advanced

- Open OBS
- Refresh connection/state

Raw scene/source listing can be added later behind an explicit Advanced affordance,
but should not be the default dropdown.

## OBS Naming Contract

The bar should rely on a small stable naming contract.

Preferred scene names:

- `Screen`
- `Screen + Camera`
- `Camera Only`

Preferred input/source names:

- `Mic`
- `Desktop Audio`
- `Camera`

Current observed OBS profile:

- scene: `Scene`
- audio inputs: `Desktop Audio`, `Mic/Aux`

The first implementation maps the UI label `Mic` to OBS input `Mic/Aux`.
The preset buttons are present but unavailable until matching scenes are created
or a scene-name mapping is added.

If the existing OBS profile uses different names, either:

1. rename the OBS scenes/sources to match this contract, or
2. add a small mapping object in `ObsCtl.qml`.

Start with option 2 only if current OBS names are known and stable.

## Implementation Plan

1. Add a Hyprland helper script for OBS window lifecycle:
   - inspect `hyprctl clients -j`
   - find OBS by class/title
   - launch when absent
   - focus when present elsewhere
   - hide focused OBS to `special:obs`
   - show/focus hidden OBS
2. Add service commands in `ObsCtl.qml` for launch/focus/hide/open behavior.
3. Simplify `ObsPopup.qml`:
   - keep recording start/stop/pause controls
   - replace raw scene flow with preset buttons
   - replace raw input list with Mic/Desktop/Camera toggles
   - remove or hide streaming, virtual cam, replay buffer from the default view
4. Keep `obs-ctl-daemon.py` as the WebSocket backend unless the simplified UI needs
   a missing request type.
5. Update `rices/limerence/docs/widgets-and-services.md` with the new OBS widget
   responsibilities.

## Verification

- With OBS closed, clicking the icon launches OBS.
- With OBS open elsewhere, clicking the icon switches to/focuses that workspace.
- With OBS focused, clicking the icon hides it to `special:obs`.
- Recording can start and stop from the dropdown after OBS is connected.
- Preset buttons switch the expected OBS scenes.
- Mic/Desktop/Camera controls affect only the expected inputs.
