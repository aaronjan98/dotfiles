# ROADMAP.md

This file is the high-level roadmap index for dotfiles-managed config across `$HOME`.

Keep only the most important workflow issues and cross-cutting features here. Push detailed notes down into area-specific `ROADMAP.md` files when they exist.

---

## Current top priorities

### OpenCode database migration runs on every launch
- See `~/.config/opencode/ROADMAP.md` for details and upstream issue links
- This is an OpenCode bug, NOT related to local config changes

### Fix popup tmux terminal workflow
- the popup tmux terminal binding is currently broken in practice
- the desired end state is a reliable popup terminal on `Alt+p`
- implementation lives in `~/nixos-config/modules/tmux.nix`, so detailed notes belong in `~/nixos-config/docs/ROADMAP.md`

### Add a live runtime theme switcher
- this spans Quickshell, Hyprland, terminals, and app themes
- the current preferred direction is `matugen` + generated theme outputs + symlink switching, not Stylix
- detailed notes currently live in `~/nixos-config/docs/ROADMAP.md`

---

## Roadmap index

### Existing roadmap files
- `~/.config/opencode/ROADMAP.md` — OpenCode configuration, deferred fixes, and known bugs
- `~/.pi/ROADMAP.md` — Pi agent configuration, deferred fixes, and future features
- `~/nixos-config/docs/ROADMAP.md` — NixOS system configuration and operational tooling backlog

### Likely future roadmap homes
- `~/.config/quickshell/ROADMAP.md` — if the shell/theme backlog grows beyond a few session notes
- `~/.config/hypr/ROADMAP.md` — if keybind, workspace, and window-management backlog grows
- `~/.config/ai/ROADMAP.md` — if the shared agent framework develops a larger future-work queue

---

## How to use this file

- keep this file high-level and cross-cutting
- when one area accumulates multiple deferred issues or planned features, create a local `ROADMAP.md` there and link it from here
- move stable architectural decisions into the most relevant `CONTEXT.md` or `MEMORY.md`
- keep session-specific implementation details in `memory/` notes instead of bloating this file
- cross-repo items are okay here when they directly affect the day-to-day dotfiles workflow
