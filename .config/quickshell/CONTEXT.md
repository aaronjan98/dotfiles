# CONTEXT.md

## Project
Quickshell dotfiles — custom QML shell for Hyprland.

## Before doing any work
1. Read `README.md` — multi-rice architecture, symlink switching, directory layout.
2. Read `rices/limerence/docs/README.md` — documentation map and fast-start reading order.
3. Read the specific doc(s) relevant to your task:
   - `docs/architecture.md` — screen composition and component hierarchy
   - `docs/window-model.md` — PanelWindow roles, layering, click-through
   - `docs/workspaces-and-state.md` — domain/slot navigation model
   - `docs/widgets-and-services.md` — bar widgets and their service dependencies
   - `docs/notifications.md` — notification subsystem pipeline
   - `docs/appearance-and-scaling.md` — Appearance.qml tokens, how to make visual changes

Do not edit code before reading the relevant doc. The docs explain design decisions worth preserving.

## After implementing a feature or making a structural change
Update the relevant doc in `rices/limerence/docs/`. If no doc covers the area, add one and
register it in `docs/README.md`.

## Active rice
`limerence` — `rices/current` symlinks here.

## How to reload after changes
```bash
qs -r
# or force a full restart:
pkill qs && qs -p ~/.config/quickshell/shell.qml
```

## How to commit
Dotfiles are tracked via the bare repo at `~/.dotfiles`. Use the `dot` command.
Always use absolute paths with `dot add` (relative paths double-nest under `.config/`):
```bash
dot add /home/aj/.config/quickshell/<file>
dot ci -m "imperative present-tense summary"
```

## Planned integrations
See `project-memory/notifications.md` for the notification integration checklist.
