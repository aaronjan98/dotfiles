# Window and Layer Model

This setup uses multiple `PanelWindow`s intentionally. Understanding the layer model is essential because many future bugs or styling decisions come down to the difference between:

- reserving space
- drawing visuals
- receiving input
- hosting popups
- hosting subsystem overlays such as notifications

## TopBar

`TopBar.qml` is a `PanelWindow` that reserves space at the top of the screen.

### Responsibilities

- create a top lane for interactive widgets
- reserve the top area so tiled Hyprland windows sit below it
- host widgets such as:
  - the left system pill
  - the centered workspace slot island
  - the right system pill
- act as the logical anchor for top popups:
  - Wi-Fi
  - Bluetooth
  - brightness

### Important behavior

- uses `ExclusionMode.Auto`
  - Hyprland will respect its reserved space
- is mostly transparent
  - the bar itself is not the main visual skin
  - the visual frame is drawn elsewhere

### Why it exists separately

A top bar must reserve space and host input. Those are not the same concerns as decorative frame rendering.

## LeftBar

`LeftBar.qml` is another `PanelWindow`, this time reserving space along the left side.

### Responsibilities

- reserve a left-side lane
- host the vertical workspace domain island
- host the bottom power button
- own the power popup relationship

### Important behavior

- uses `ExclusionMode.Auto`
  - tiled windows are pushed rightward
- is transparent and interactive
  - like `TopBar`, it is a lane, not the primary visual skin

## ContentFrame

`ContentFrame.qml` is the visual shell frame.

### Responsibilities

- draw the tinted ring around the content area
- define the carved / concave look
- draw glow and inner border effects inside the content hole
- visually unify top and left reserved regions with the content region

### Critical design detail

This window is **visual only**.

- it should not reserve space
- it should not intercept input
- it should sit behind interactive windows

### How input is disabled

The file uses the empty-region mask technique:

- `mask: Region { }`
  - this makes the window click-through
  - input falls through to interactive windows beneath or above as intended

### Why this matters

Without click-through behavior:

- bars might become unclickable
- popups might appear visually but fail to receive input
- the frame would act like invisible glass over the desktop

## CornerPatch

`CornerPatch.qml` is a special overlay window for the Nix bubble.

### Why it exists

The top-left bubble is special because:

- it sits at the edge where the frame geometry is visually complex
- it needs reliable click behavior
- it must not be clipped by parent bar geometry

### Responsibilities

- host the Nix bubble
- sit above the frame and bars
- isolate input handling for that element

### Why this was a good decision

This simplifies correctness:

- the bubble is always in a guaranteed overlay context
- it avoids subtle layering bugs
- future experiments can move it later, but the current design is robust

## Popup windows

Several widgets create their own popup `PanelWindow`s rather than rendering popups inline in the bar.

This is the correct pattern because popups often need to:

- draw outside the dimensions of the bar window
- appear on a higher layer than the bar
- optionally use a scrim or fullscreen click-catcher
- manage keyboard focus independently

Examples known from the setup:

- `WifiPopup.qml`
- `BluetoothPopup.qml`
- `BrightnessPopup.qml`
- `PowerPopup.qml`

## Notification windows

The notification system follows the same multi-window philosophy, but as its own subsystem.

### `NotifLayer.qml` owns multiple windows

At a broad level it manages:

- a toast window
  - shows a stack of transient notification cards
  - becomes visible only when popup notifications exist
- a scrim window
  - catches clicks outside the notification center
  - closes the center when the user clicks away
- a center window
  - slides the notification history panel in and out
  - hosts `NotificationCenter.qml`

### Why notifications are not just another popup

Notifications have different requirements from a one-off popup:

- popup toasts need to appear even when the center is closed
- the center needs its own open/close lifetime
- the center needs a click-out scrim
- toast animation and center animation are separate concerns
- the subsystem is driven by service state rather than a single button's local state

That is why the notification layer is better thought of as a small overlay system rather than a single widget.

## Exclusion model summary

### `ExclusionMode.Auto`

Used by:

- `TopBar`
- `LeftBar`

Meaning:

- these windows reserve space from tiled windows
- Hyprland lays clients around them

### `ExclusionMode.Ignore`

Used by:

- `ContentFrame`
- overlay patches
- popups
- notification overlays

Meaning:

- these windows are not part of layout reservation
- they can float visually without changing the work area

## Layer summary

### Lower / decorative layer

- `ContentFrame`
  - decorative
  - behind interactive elements

### Reserved interactive lanes

- `TopBar`
- `LeftBar`
  - user-facing input surfaces
  - participate in workspace layout

### Overlay layer

- `CornerPatch`
- popups
- notification overlays
  - highest priority for interaction and visibility

## Debugging rules of thumb

If something is visually present but cannot be clicked:

- check whether a decorative window is intercepting input
- check whether the popup belongs in its own `PanelWindow`
- check whether layering is wrong
- check whether a scrim window is still visible above the UI you expect to click

If something clips unexpectedly:

- check whether it is being drawn inside a lane window instead of a dedicated popup window
- check whether the element belongs in overlay space

If tiled windows overlap the shell unexpectedly:

- check whether the window is using `ExclusionMode.Auto`
- check whether the bar dimensions match the intended reservation dimensions

If the notification center does not close or blocks clicks:

- inspect the ordering and visibility of the notification scrim window
- inspect whether `centerOpen` service state and window visibility state are still aligned
