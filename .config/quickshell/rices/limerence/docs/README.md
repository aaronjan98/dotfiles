# Quickshell / Hyprland Setup Documentation

This directory documents the architecture of the `limerence` Quickshell rice and explains how its pieces fit together.

## What this setup is

This Quickshell configuration builds a custom shell UI for Hyprland with five major visual or interactive subsystems:

- a **top bar**
  - reserves space at the top of the screen
  - hosts the horizontal workspace "slot" island in the center
  - hosts system and status pills on the left and right
  - acts as the anchor point for several popups, including Wi-Fi, Bluetooth, and brightness
- a **left bar**
  - reserves space along the left edge of the screen
  - hosts the vertical workspace "domain" island
  - hosts the bottom power button
  - acts as the anchor point for the power popup
- a **visual content frame**
  - draws the carved / concave / ring-like frame around the usable content region
  - is purely visual and should not intercept input
  - exists behind the interactive bars and bubbles
- a **corner overlay patch**
  - hosts the Nix bubble in the top-left corner
  - sits above the frame and above the bars for reliable interaction
  - is intentionally separated so the Nix bubble is always clickable and visually stable
- a **notification subsystem**
  - receives desktop notifications through a central service
  - renders transient toasts in an overlay layer
  - renders a sliding notification center for history and controls
  - connects bar UI, overlay windows, and service state into one coherent flow

## Core design ideas

- **Window separation is intentional**
  - visual-only surfaces are separated from interactive surfaces
  - this prevents decorative layers from interfering with clicks or focus
  - each window has a clear role: reserve space, draw visuals, or handle input
- **Per-screen composition is explicit**
  - each monitor gets its own shell scene
  - the scene is composed in a small number of top-level files
  - this makes multi-monitor behavior easier to reason about
- **Appearance is centralized**
  - sizing, padding, radii, colors, and other theme tokens live in `config/Appearance.qml`
  - appearance is meant to be the shared vocabulary for shell density and styling
  - components should gradually move toward using shared tokens instead of local magic numbers
- **State and services are separated from widgets**
  - widgets render UI and handle interaction
  - services provide system data and commands
  - state files keep UI navigation memory separate from rendering code
- **Workspace navigation is two-dimensional**
  - the top bar represents slots within a domain
  - the left bar represents domains
  - together they form a 2D mental model for workspace navigation
- **Notifications are treated like a subsystem, not just a widget**
  - one service owns notification state and history
  - one overlay layer owns notification windows
  - bar UI such as the notification icon only acts as an entry point into that system

## Documentation map

- [`architecture.md`](./architecture.md)
  - broad architectural overview
  - screen composition
  - layering model
  - parent-child relationships between major components
- [`window-model.md`](./window-model.md)
  - explains each `PanelWindow`
  - details exclusion behavior, layer behavior, and click-through strategy
- [`workspaces-and-state.md`](./workspaces-and-state.md)
  - explains domains, slots, workspace mapping, and the navigation state model
- [`widgets-and-services.md`](./widgets-and-services.md)
  - documents bar widgets, popup widgets, and the system service providers they depend on
- [`notifications.md`](./notifications.md)
  - explains the notification subsystem as a whole
  - shows how `Notifs.qml`, `NotifLayer.qml`, `NotificationToast.qml`, `NotificationCenter.qml`, and the bar icon relate to each other
- [`appearance-and-scaling.md`](./appearance-and-scaling.md)
  - explains `Appearance.qml`
  - explains how sizing and scaling are intended to work
- [`known-files-and-gaps.md`](./known-files-and-gaps.md)
  - lists files that are known from inspection
  - notes what is only partially known or inferred
  - highlights where further documentation could be expanded later

## Quick mental model

If you only remember one thing, remember this flow:

- `shell.qml` creates one shell scene per screen
  - each scene is a `FrameRoot`
    - `FrameRoot` builds the major windows for that screen
      - `ContentFrame` draws the carved visual frame
      - `TopBar` hosts top widgets and popup anchors
      - `LeftBar` hosts left widgets and popup anchors
      - `CornerPatch` hosts the top-left Nix bubble overlay
      - notification overlays are wired alongside those screen-level windows
- appearance values come from `Appearance.qml`
- workspace memory and navigation state come from `components/state/*`
- system data and actions come from `components/services/*`
- widgets in `components/widgets/*` present the UI and call into state or services
- the notification system has its own service-to-overlay pipeline
  - `Notifs.qml` receives and normalizes notifications
  - `NotifLayer.qml` owns the toast stack and notification center windows
  - `NotificationToast.qml` renders individual cards
  - `NotificationCenter.qml` renders the persistent history panel
  - `NotificationIcon.qml` is the top-bar entry point

## Intended audience

These docs are written for someone who needs to:

- understand the setup before changing it
- add or restyle widgets
- debug why a widget belongs in one window instead of another
- change the workspace UI
- adjust theme tokens or bar dimensions
- continue the work of centralizing sizes and reducing magic numbers
- understand how notifications fit into the shell rather than treating them as an isolated feature

## Fast start for a new contributor

Read in this order:

1. `README.md`
   - get the high-level picture
2. `architecture.md`
   - understand how the scene is composed
3. `window-model.md`
   - understand why multiple windows are used
4. `workspaces-and-state.md`
   - understand how navigation works
5. `widgets-and-services.md`
   - understand where data and behavior come from
6. `notifications.md`
   - understand the notification pipeline as a system
7. `appearance-and-scaling.md`
   - understand how to make visual changes safely

## Current status of this documentation

This documentation covers the main shell composition, workspace model, core bar widgets, the Wi-Fi and Bluetooth popup pattern, the `WifiNm` service, the `SystemStats` data provider, and the notification pipeline.

Please see the full files for component specifications on:

- `BrightnessPopup.qml`
- `PowerPopup.qml`
- `PowerIcon.qml`
- some non-notification service internals such as volume, battery, brightness, and gamma control helpers
