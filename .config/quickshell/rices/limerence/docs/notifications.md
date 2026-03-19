# Notification Subsystem

The notification system is one of the clearest examples in this shell of a feature that spans more than one file category.

It is not just:

- one icon in the bar
- one popup window
- one service file

It is a small subsystem with its own service state, overlay windows, reusable card widget, and optional IPC entry points.

## The big picture

At a broad level, the flow looks like this:

- applications send desktop notifications
- `Notifs.qml` receives them through a notification server
- the service normalizes and stores them
- `NotifLayer.qml` turns that state into overlay windows
  - transient toasts
  - notification-center scrim
  - sliding notification center
- `NotificationToast.qml` renders individual notifications
- `NotificationCenter.qml` renders the persistent history panel
- `NotificationIcon.qml` exposes unread status and toggles the center from the top bar
- `NotifsIpc.qml` exposes external control through `qs ipc`

## Why the system is split this way

### `Notifs.qml` is the source of truth

This file owns the notification state, not the widgets.

That includes:

- history model
- popup model
- unread count
- DND state
- whether the center is open
- action dispatch and activation behavior

This separation matters because:

- overlay windows can come and go
- the bar icon can be recreated with the bar
- notification history still needs a stable owner

### `NotifLayer.qml` owns screen-level behavior

This file is where notification state becomes visible overlay behavior.

It manages multiple window surfaces:

- a toast stack
- a scrim for click-out closing
- a sliding center window

This separation matters because the service should not own window geometry, layering, or animation.

### `NotificationToast.qml` is the reusable card view

This file renders one notification entry and is reused in two contexts:

- toast popup stack
- notification center history list

This is important because:

- the same notification can appear transiently and then persist in history
- a shared card component keeps interaction and styling consistent

### `NotificationCenter.qml` is the persistent panel

This file renders the long-lived side panel with:

- DND toggle
- clear button
- close button
- history list

This keeps history-specific controls separate from the general toast-card presentation.

### `NotificationIcon.qml` is just the bar entry point

The icon is intentionally small in scope.

It does not own notification data. It only:

- reflects unread count
- toggles the center

That keeps the top bar simple.

## Main responsibilities by file

### `components/services/Notifs.qml`

High-level role:

- core notification service singleton

System role:

- receives incoming notifications
- stores live notification objects separately from model entries
- normalizes actions for the UI
- decides what goes into popup toasts vs history
- exposes actions such as dismiss, invoke, activate, and clear all

Why it matters to the whole system:

- every notification UI surface depends on this file
- it is the service boundary between the daemon-facing world and the widget-facing world

### `components/frame/NotifLayer.qml`

High-level role:

- overlay host for notification windows

System role:

- renders the stack of transient toasts
- renders the click-out scrim when the center is open
- renders the sliding center window
- listens to service state to animate open and close behavior

Why it matters to the whole system:

- this is where the notification subsystem touches the screen-level window model
- it makes notifications a first-class overlay system alongside other shell surfaces

### `components/widgets/NotificationToast.qml`

High-level role:

- reusable notification card widget

System role:

- renders notification summary, body, icon or image, and actions
- activates notifications on click
- dismisses notifications on close
- invokes action buttons

Why it matters to the whole system:

- it is the shared presentation unit for both transient and persistent notification views

### `components/widgets/NotificationCenter.qml`

High-level role:

- persistent notification-history panel

System role:

- renders controls such as DND, clear all, and close
- renders notification history using `NotificationToast.qml`
- handles the "empty state" when no history exists

Why it matters to the whole system:

- it is the long-lived user-facing control surface for the subsystem

### `components/services/NotifsIpc.qml`

High-level role:

- command bridge for external control

System role:

- exposes actions like:
  - toggle center
  - open center
  - close center
  - toggle DND
  - clear all
- makes notification behavior controllable from keybinds and CLI

Why it matters to the whole system:

- it means the subsystem is not only UI-driven; it can also be automation- or keybind-driven

## Important interactions

### When a new notification arrives

Broad flow:

- the service receives the live notification object
- it converts relevant fields into plain model data
- it inserts a history entry
- if the notification should surface as a popup, it also inserts a popup entry
- unread count increases when the center is not open

### When a toast is clicked

Broad flow:

- `NotificationToast.qml` calls back into `Notifs.qml`
- the service tries to invoke the default action if present
- if no default action exists, the service can fall back to focusing the sender process via Hyprland

### When the notification center is toggled

Broad flow:

- the bar icon or IPC layer triggers a service method
- `Notifs.qml` changes center-open state
- `NotifLayer.qml` reacts by showing or hiding the center window and scrim

### When the user clears notifications

Broad flow:

- `NotificationCenter.qml` calls into the service
- `Notifs.qml` dismisses and removes tracked notifications
- popup and history models are updated from the service side

## Design decisions worth preserving

### Service data is separated from UI models

A key design detail is that live notification objects are kept outside the `ListModel`.

That is the right choice because:

- models should store plain data used by delegates
- live daemon objects are not a good fit for model storage
- action invocation still needs access to the original live object

### The center uses `Flickable + Column + Repeater`

The notification center intentionally avoids a more automatic list abstraction here.

That keeps the center aligned with the notification card widget and avoids role or delegate issues that came up during development.

### Overlay windows are kept separate

The subsystem uses separate windows for toast stack, scrim, and center.

That is a strength, not a complication, because each surface has a different job and different input behavior.

## Practical debugging guidance

If unread count is wrong:

- inspect `Notifs.qml`
- verify when unread increments and when it resets

If the icon updates but the center does not open:

- inspect the service state used for center visibility
- inspect `NotifLayer.qml` open or close wiring

If the center opens but cannot be closed by clicking outside:

- inspect the scrim window and its visibility ordering

If a notification card shows but clicking it does nothing:

- inspect `defaultKey_` handling
- inspect service `activate()` logic
- inspect whether the sender app actually exposed a default action

If avatars or rich images do not show:

- inspect whether the sending app included image hints at all
- the UI can only display what the app actually provided

## Short mental model

The shortest useful summary is:

- `Notifs.qml` owns notification state
- `NotifLayer.qml` owns notification windows
- `NotificationToast.qml` renders one notification
- `NotificationCenter.qml` renders history and controls
- `NotificationIcon.qml` is the top-bar entry point
- `NotifsIpc.qml` lets the subsystem be controlled externally
