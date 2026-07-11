# External Monitor Workspace Model

Status: simplified model in progress

## Goal

Keep the workspace model simple and Hyprland-native:

- The Framework screen keeps the normal 2D workspace grid.
- The Samsung external monitor gets one dedicated horizontal row.
- No fake cloning of every laptop workspace onto the external monitor.
- No attempt to show the same real workspace on both monitors.

Hyprland cannot display the same real workspace on two non-mirrored monitors at once. If both monitors try to show workspace `5`, Hyprland moves or focuses that workspace instead of duplicating it.

## Workspace Layout

Framework/laptop workspaces:

```text
domain 1, slot 1 -> workspace 1
domain 1, slot 9 -> workspace 9
domain 2, slot 1 -> workspace 21
domain 9, slot 9 -> workspace 99
```

External monitor workspaces:

```text
external slot 1 -> workspace 101
external slot 2 -> workspace 102
external slot 9 -> workspace 109
```

This means the external monitor is effectively domain `10`.

## UI Model

- The external TopBar shows horizontal slot dots for workspaces `101..109`.
- The laptop TopBar shows horizontal slot dots for the current laptop domain.
- The laptop LeftBar shows laptop domain dots.
- A divider and an external monitor dot can be added to the laptop LeftBar to show that domain `10` belongs to the external monitor.
- `Super+J/K` does not navigate to domain `10`; crossing the divider is pointer-only via the external dot.
- The external dot remains visible as the explicit affordance for the external row. If DP-1 is connected, clicking it focuses DP-1 and keeps its current `101..109` workspace. If DP-1 is disconnected, clicking it can still dispatch workspace `101` manually, but keyboard domain navigation will not enter it.

## Primitives

1. Determine target monitor.
   - Keyboard navigation uses Hyprland's focused monitor.
   - Bar clicks use the bar's `screen.name`.

2. Determine target domain.
   - `eDP-1`: use the active workspace's domain.
   - `DP-1`: always use domain `10`.

3. Convert domain + slot to workspace id.
   - Domain `1`: workspace id is the slot.
   - Domains `2+`: workspace id is `domain * 10 + slot`.

4. Dispatch to Hyprland using the real workspace id.

## Checkpoints

### Checkpoint 1: Monitor Detection

Run with the cursor on each monitor:

```bash
~/.config/hypr/scripts/ws-current-monitor.sh debug
```

Expected:

```text
monitor=eDP-1 ...
monitor=DP-1 ...
```

Run after changing monitor focus with `Super+arrow`:

```bash
~/.config/hypr/scripts/ws-current-monitor.sh focused
```

Expected: the reported monitor matches the monitor that currently has Hyprland focus.

### Checkpoint 2: Mapping

```bash
~/.config/hypr/scripts/ws-map eDP-1 slot 5
~/.config/hypr/scripts/ws-map DP-1 slot 5
~/.config/hypr/scripts/ws-map eDP-1 domain-slot 2 1
```

Expected:

```text
5
105
21
```

### Checkpoint 3: Slot Navigation

- Cursor on eDP-1: `Super+H/L` navigates the current laptop row.
- Cursor on DP-1: `Super+H/L` navigates `101..109`.
- No focus stealing occurs from both monitors trying to own the same workspace.

### Checkpoint 4: Quickshell Display

- Laptop TopBar displays normal laptop row slots.
- External TopBar displays slots for `101..109` as `1..9`.
- Laptop LeftBar can show a divider plus external dot for domain `10`.

### Checkpoint 5: Domain Navigation

- `Super+J/K` remains laptop-domain navigation.
- On DP-1, domain navigation should either do nothing or focus the laptop, but it should not create cloned external domains.
- The LeftBar shows a divider plus one external dot after the laptop domain dots.

### Checkpoint 6: Move Window Commands

- Moving a laptop window to slot `5` uses the current laptop domain.
- Moving an external window to slot `5` uses workspace `105`.
