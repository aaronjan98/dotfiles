# Architecture Overview

## Top-level composition

The entry point for the shell is `shell.qml`.

Its job is simple:

- it iterates over `Quickshell.screens`
- it creates one `FrameRoot` per screen
- each `FrameRoot` composes the major windows for that monitor

That means the shell is fundamentally **per-screen** rather than global.

## The main screen-level composition

For each screen, `FrameRoot.qml` is the structural root.

At a broad level, it is responsible for assembling the shell into a small number of major surfaces:

- `ContentFrame`
  - decorative carved frame around the usable content region
- `TopBar`
  - interactive top lane and popup anchor surface
- `LeftBar`
  - interactive left lane and popup anchor surface
- `CornerPatch`
  - top-left overlay bubble host
- notification overlay surfaces
  - later additions such as `NotifLayer.qml` live at this same screen-composition level
  - they are not just child widgets inside the top bar; they are their own overlay windows

## Architectural layers

This setup is easiest to understand as a stack of responsibilities.

### 1. Composition layer

Files:

- `shell.qml`
- `components/frame/FrameRoot.qml`

Responsibilities:

- create a shell scene per monitor
- decide which top-level windows exist
- wire each window to the current `ShellScreen`

### 2. Window and layout layer

Files:

- `components/frame/TopBar.qml`
- `components/frame/LeftBar.qml`
- `components/frame/ContentFrame.qml`
- `components/frame/CornerPatch.qml`
- `components/frame/NotifLayer.qml`

Responsibilities:

- reserve compositor space where needed
- define which surfaces are interactive vs visual only
- anchor popups and overlay systems to the correct screen-level context
- separate lanes, overlays, and decorative surfaces into independent windows

### 3. Widget layer

Files under:

- `components/widgets/`

Responsibilities:

- render visible UI elements
- respond to clicks, taps, scrolling, and keys
- call into services or state helpers instead of owning heavy system logic themselves

Examples:

- workspace islands
- top bar icons
- popup contents
- notification cards
- notification center panel

### 4. State layer

Files under:

- `components/state/`

Responsibilities:

- keep UI-specific memory and navigation context separate from rendering code

Examples:

- `NavState.qml`
  - previous navigation direction/context
- `DomainMemory.qml`
  - remembered slot per domain

### 5. Service layer

Files under:

- `components/services/`

Responsibilities:

- talk to the outside world
- fetch data
- run commands
- normalize system-facing information into widget-friendly state

Examples:

- `WifiNm.qml`
- `VolumeCtl.qml`
- `BrightnessCtl.qml`
- `BatterySys.qml`
- `Notifs.qml`

## A recurring pattern: local UI state + service backend

A useful way to read this rice is to separate three different kinds of responsibility that often appear together in one feature:

- a small amount of local widget state
  - for example, whether a popup is currently open
  - or whether a password sub-form is visible inside that popup
- a backend or data provider
  - for example, `WifiNm.qml` for Wi-Fi state and commands
  - or `SystemStats.qml` for CPU and memory values shown in the bar
- one or more windows that present the UI
  - for example, `TopBar.qml` for the entry point and `WifiPopup.qml` for the overlay controls

This matters because it keeps the system readable:

- bars stay focused on composition and anchoring
- services stay focused on outside-world integration
- popup widgets stay focused on interaction and presentation

The Wi-Fi feature is a good example of this split:

- `TopBar.qml` owns the open or close state
- `WifiIcon.qml` is only the clickable status display
- `WifiPopup.qml` owns overlay presentation, focus, and inline password UI
- `WifiNm.qml` owns scanning, parsing, and `nmcli` commands

The notification system uses the same philosophy at a larger scale.

## Two major system flows

There are two especially important flows in this shell.

### Workspace flow

This is the navigation spine of the shell:

- Hyprland reports focused workspace and workspace contents
- `TopBar.qml` derives current domain and slot
- `LeftBar.qml` derives current domain and domain occupancy
- `DotTrack.qml` renders the slot and domain islands
- `DomainMemory.qml` remembers the last slot used in each domain
- user interaction dispatches `Hyprland.dispatch("workspace ...")`

### Notification flow

This is the event-and-overlay subsystem:

- `Notifs.qml` receives notifications from the notification server
- it normalizes incoming data and stores:
  - active popup entries
  - full history entries
  - unread count
  - DND and center-open state
- `NotificationIcon.qml` reflects unread state and toggles the center
- `NotifLayer.qml` owns the windows that render:
  - transient toast stack
  - scrim for click-out closing
  - sliding notification center
- `NotificationToast.qml` renders one notification card
- `NotificationCenter.qml` renders the scrollable history panel and controls
- `NotifsIpc.qml` lets external commands control this subsystem through `qs ipc`

## Why the shell is structured this way

### Clear separation of concerns

This shell avoids putting everything into a single giant bar file.

That matters because these concerns are different:

- compositor layout reservation
- visual frame drawing
- system integration
- widget rendering
- persistent UI state
- event-style subsystems like notifications

Keeping them separate makes the codebase easier to reason about.

### Overlay-heavy features stay independent

Popups and notifications are their own windows because they need behaviors that inline widgets do not:

- screen-relative placement
- independent input capture
- independent focus behavior
- draw outside the bar lane
- appear above the bars and decorative frame

### Styling stays centralized

`Appearance.qml` exists so the system has one visual vocabulary.

That keeps concepts like these consistent across the shell:

- bar thickness
- corner radius
- bubble padding
- frame border color
- popup density

## Modification guidance

When changing the shell, first identify which architectural layer your change belongs to.

### If you are changing screen composition

Look at:

- `shell.qml`
- `FrameRoot.qml`

### If you are changing window behavior or layering

Look at:

- `TopBar.qml`
- `LeftBar.qml`
- `ContentFrame.qml`
- `CornerPatch.qml`
- `NotifLayer.qml`

### If you are changing what the user sees inside a window

Look at:

- files under `components/widgets/`

### If you are changing remembered UI behavior

Look at:

- files under `components/state/`

### If you are changing system data, commands, or daemon integration

Look at:

- files under `components/services/`

## The shortest possible mental model

You can summarize the whole shell like this:

- `shell.qml` creates one scene per monitor
- `FrameRoot.qml` assembles the windows for that scene
- frame files define where UI can live and how it layers
- widget files define what the UI looks like and how it behaves
- state files remember navigation context
- service files connect the UI to Hyprland, NetworkManager, PipeWire, brightness tools, Bluetooth, and notifications
