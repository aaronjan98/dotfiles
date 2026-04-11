# 2026-04-10 22:03 — tmux popup binding

## What was worked on
Added a `C-t` keybinding to the tmux config in nixos-config to open a scratch terminal popup.

## Key decisions
- Main tmux config lives in `/home/aj/nixos-config/modules/tmux.nix` (NixOS module, generates `/etc/tmux.conf`)
- `~/.config/tmux/` contains only the `resurrect/` snapshot directory — no config files there
- The correct tmux command is `display-popup` (not `popup`)
- Used `bind -n C-t display-popup -E -w 80% -h 75%` — `-n` makes it prefix-free
- Added under a new `##### Popups #####` section before pane management bindings

## Next steps
- Run `nixos-rebuild switch` to apply the change
