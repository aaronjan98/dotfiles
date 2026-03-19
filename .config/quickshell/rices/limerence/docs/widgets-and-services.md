# Widgets and Services

This setup separates visual widgets from system-facing services.

That split is important:

- widgets should mostly concern themselves with rendering and interaction
- services should mostly concern themselves with data, commands, and system integration
- larger subsystems, such as notifications, should be read as service plus overlay windows plus bar entry point

## Services

The known service layer lives in `components/services/`.

### `BatterySys.qml`

Known role:

- provide battery status information
- expose at least:
  - battery percent
  - whether battery information is available
  - charging and full state

Used by:

- `BatteryIcon.qml`

### `VolumeCtl.qml`

Known role:

- provide volume state and control actions
- integrates with `wpctl`
- exposes concepts such as:
  - current percent
  - mute state
  - whether headphones are active
  - delta adjustment behavior

Used by:

- `VolumeIcon.qml`

### `BrightnessCtl.qml`

Known role:

- manage screen brightness and keyboard backlight
- integrates with `brightnessctl`
- provides current values and set operations

Used by:

- `BrightnessIcon.qml`
- `BrightnessPopup.qml`

### `GammaCtl.qml`

Known role:

- manage temperature / gamma-like behavior
- supports a slider-style 0 to 100 temperature percentage abstraction

Used by:

- `BrightnessPopup.qml`

### `WifiNm.qml`

Known role:

- central Wi-Fi service built on NetworkManager and `nmcli`
- track whether Wi-Fi is enabled
- track current connection state, active SSID, and signal strength
- maintain a deduplicated list of visible networks for the popup
- provide actions for rescan, toggle, disconnect, and connect

System-facing behavior:

- polls status regularly rather than relying on a push API
- parses `nmcli` output into widget-friendly state
- sorts networks so the active network and strongest networks are easier to surface in the UI
- includes a fallback connection path for cases where the first `nmcli dev wifi connect` attempt fails because a connection profile must be created explicitly

Used by:

- `WifiIcon.qml`
- `WifiPopup.qml`

Why it matters:

- it is the source of truth for the entire Wi-Fi experience in the shell
- the icon only reflects state from this service
- the popup is mostly a control surface layered on top of this service, not an independent backend

### `Notifs.qml`

This is not just a badge counter. It is the core notification service.

Known role:

- receive incoming desktop notifications through a notification server
- normalize notification data into model-friendly entries
- maintain:
  - popup notification model
  - history model
  - unread count
  - DND state
  - notification-center open state
- expose actions such as:
  - dismiss
  - activate
  - invoke
  - clear-all
  - open or close the center

Used by:

- `NotificationIcon.qml`
- `NotifLayer.qml`
- `NotificationCenter.qml`
- `NotificationToast.qml`
- `NotifsIpc.qml`

Why it matters:

- it is the source of truth for the entire notification subsystem
- widgets do not talk directly to notification daemon objects; they talk to this service

### `NotifsIpc.qml`

Known role:

- expose notification actions through `qs ipc`
- let external commands or keybinds control the notification subsystem

Used for:

- toggling the center
- opening or closing the center
- toggling DND
- clearing all notifications
- in later versions, dismissing or invoking individual notifications

### `SystemStats.qml`

Known role:

- lightweight data-provider component for CPU and memory usage
- polls Linux procfs rather than using a desktop-specific system API

System-facing behavior:

- computes CPU usage from deltas in `/proc/stat`
- computes memory usage from `/proc/meminfo`, using `MemAvailable` rather than a simpler but less useful total-minus-free metric
- encapsulates the shell-command and parsing logic so `TopBar.qml` can stay focused on layout

Used by:

- the left system pill in `TopBar.qml`

Why it matters:

- it is a good example of the design split in this rice: data gathering lives in a small non-visual component, while the bar itself just renders the resulting values

## Widgets

The widget layer lives in `components/widgets/`.

## Core container widgets

### `Pill.qml`

Purpose:

- render pill-shaped containers used for side islands in the bar
- apply background, padding, and border consistently
- let child content define the interior

Important properties:

- `useBackground`
- `padX`
- `padY`
- content via default property alias

Why it matters:

- centralizes the look of side islands
- changing pill padding or border changes many bar widgets at once

### `BubbleItem.qml`

Purpose:

- render rounded bubble-style containers
- support square forced sizing or content-driven sizing
- optionally support direct click handling

Used for:

- workspace islands
- likely other rounded, compact bubble containers

### `DotTrack.qml`

Purpose:

- generic dot or pill track for slot and domain navigation

## Top bar widgets

### `BatteryIcon.qml`

Known behavior:

- shows battery glyph plus percentage
- colors the icon based on percent
- animates while charging

### `VolumeIcon.qml`

Known behavior:

- shows volume glyph plus percentage
- changes glyph for muted, headphones, or loudness level
- supports mouse-wheel volume adjustment

### `WifiIcon.qml`

Known behavior:

- shows Wi-Fi status glyph
- reacts to enabled, connected, and signal strength state
- emits click for popup toggling

### `BluetoothIcon.qml`

Known behavior:

- shows Bluetooth glyph and enabled or connected visual state
- emits click for popup toggling

### `BrightnessIcon.qml`

Known behavior:

- shows brightness glyph by current brightness level
- emits click for popup toggling

### `NotificationIcon.qml`

Known behavior:

- shows a notification bell icon
- displays an unread badge when unread count is greater than zero
- toggles the notification center on tap

How it fits the system:

- it is the notification subsystem's entry point in the top bar
- it does not own notification state itself
- it reflects and manipulates `Notifs.qml` state

### `Clock.qml`

Known role:

- small display widget for current date and time
- updates itself on a timer and formats time through Qt

Used by:

- the right-side pill in `TopBar.qml`

Why it matters:

- this is intentionally a tiny self-updating widget rather than logic embedded into the top bar
- it keeps time formatting concerns local to the clock component

## Popup widgets

### `WifiPopup.qml`

Known behavior:

- is instantiated by `TopBar`, but creates its own popup and scrim windows
- uses `WifiNm.qml` as its backend rather than owning connection logic itself
- supports:
  - Wi-Fi on/off toggle
  - rescan action
  - list of networks
  - secure network password entry
  - disconnecting from the active network
  - inline error display when a connection fails

Why it matters:

- it demonstrates the popup pattern used throughout the rice:
  - the bar owns a small piece of local open or close state
  - the popup owns its own overlay windows and focus handling
  - the service owns the actual system integration
  - connect or disconnect behavior

### `BluetoothPopup.qml`

Known behavior:

- attaches to `TopBar`
- includes enabled toggle and discovering toggle
- shows paired devices and recently seen devices
- supports device connection or disconnection and launch of Blueman tools

### `BrightnessPopup.qml`

Known behavior from file presence and excerpts:

- attaches to `TopBar`
- includes screen and keyboard brightness sliders
- includes gamma or temperature controls and toggles

### `PowerPopup.qml`

Known behavior from file presence and excerpts:

- attaches to the left-side power button
- includes actions such as lock, sleep, restart, shutdown, or related system commands
- uses its own window so it can draw outside the left reserved lane

## Notification widgets

### `NotifLayer.qml`

Known role:

- own the notification windows rather than just one notification widget
- host:
  - a toast stack window
  - a scrim window for the center
  - a sliding center window
- bridge notification service state into actual overlay windows

Why it matters:

- it is where notification UI becomes screen-level overlay behavior
- it ties together the service state and the overlay windows

### `NotificationToast.qml`

Known role:

- render one notification card
- work both as:
  - a transient popup toast
  - a row in the notification center history

Known interactions:

- card click activates the notification or app
- close button dismisses the notification
- action buttons invoke notification actions

Why it matters:

- it keeps the visual representation of one notification consistent across both transient and persistent contexts

### `NotificationCenter.qml`

Known role:

- render the persistent notification-history panel
- provide controls such as:
  - DND toggle
  - clear all
  - close center
- render history entries using `NotificationToast.qml`

Why it matters:

- it is the user's persistent view into the notification subsystem
- it reuses the same card component as toasts, but in a very different window context

## Broad dependency pattern

A good mental model is:

- services know about the system
- widgets know about presentation and interaction
- overlay hosts know how to place widgets into windows

For notifications specifically:

- `Notifs.qml` owns state and actions
- `NotifsIpc.qml` exposes command entry points
- `NotificationIcon.qml` exposes the subsystem in the bar
- `NotifLayer.qml` owns overlay windows
- `NotificationCenter.qml` and `NotificationToast.qml` render the actual UI


### `BluetoothPopup.qml`

Known behavior:

- follows the same broad popup pattern as `WifiPopup.qml`
- creates its own scrim and popup windows rather than trying to draw outside the bar inline
- uses `Quickshell.Bluetooth` directly instead of going through a separate custom service singleton
- provides:
  - adapter enable or disable toggle
  - discovering toggle and scan controls
  - paired-device list with connect, disconnect, and forget actions
  - recently seen unpaired-device list while discovering
  - launch actions for Blueman tools

Why it matters:

- it shows that not every subsystem needs a custom service file
- in this case, Quickshell's Bluetooth API provides enough live state that the popup can act as both viewer and controller with only a tiny helper process runner for external tools
- it also highlights a recurring pattern in this rice: temporary UI-specific state can live locally in a widget when it is not meaningful as global application state
