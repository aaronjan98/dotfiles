# ROADMAP.md

This file is the high-level roadmap index for dotfiles-managed config across `$HOME`.

Keep only the most important workflow issues and cross-cutting features here. Push detailed notes down into area-specific `ROADMAP.md` files when they exist.

---

## Current top priorities

### Terminal job-complete notifications: fix focus check and generalise
Two related issues:

**Bug — Claude Code hook ignores focus (always notifies):**
The current hook in `~/.claude/settings.json` uses `hyprctl activewindow` and `tmux display-message` to suppress notifications when the terminal is already focused. In practice it always fires because `HYPRLAND_INSTANCE_SIGNATURE` and `TMUX` are not propagated into the hook subprocess, causing both checks to silently fail (exit non-zero), which makes `notify-send` always run.
Fix: explicitly pass the required env vars into the hook, or rewrite to use a mechanism that doesn't depend on inherited environment (e.g. check `/proc/$PPID/environ` or write a small wrapper script that sources the vars before checking).

**Feature — General notify-on-job-complete for any process:**
Rather than wiring per-agent hooks (Claude, pi, opencode separately), implement a shell-level solution that fires for any long-running command:
- `preexec` hook: record command start time and name
- `precmd` hook: on completion, if elapsed time > threshold (e.g. 10s) and terminal not focused → send notification with command name and exit status
- Focus check: query `hyprctl activewindow` + tmux pane state (fix the env var propagation issue first)
- This replaces the claude-code Stop hook and makes per-agent setup unnecessary

Shell config lives in the dotfiles repo (`~/.config/` tracked by `~/.dotfiles`).
Relevant file to create or extend: shell rc / zsh plugin (e.g. `~/.config/zsh/notify-on-done.zsh` or similar).

---

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

### Workspace bootstrap scripts (per-domain layout restoration)
Goal:
- A set of scripts — one per vertical domain (each dot in the left-bar workspace island) — that open the right apps in the right Hyprland workspaces automatically, so the workspace layout can be recreated from scratch after a reboot or fresh session without manual setup

How each script works (intended design):
- Targets a specific domain (e.g. domain 2 = work, domain 3 = media)
- Dispatches `hyprctl dispatch exec <app>` for each app belonging to that domain
- Moves each launched window to its intended workspace slot using `hyprctl dispatch movetoworkspace` or by launching with workspace rules
- Optionally waits for each window to appear before launching the next (via `hyprctl clients` polling or `exec-once` ordering)
- Should be idempotent: if an app is already open in the right place, skip it rather than opening a second instance

Triggering (multiple independent paths — these scripts stand alone):
- Direct CLI call: `bootstrap-domain-2` or similar
- Keybinding via Hyprland directly
- Letter keypress in a future Kanata script-execution mode (see `~/nixos-config/docs/ROADMAP.md` — Kanata script mode is one trigger, not a requirement for this feature)

Implementation notes:
- Each script needs a mapping of: domain → [(app command, workspace slot, optional window rules)]
- Window positioning may require `windowrulev2` entries in Hyprland config or `hyprctl dispatch movetoworkspace` after launch
- A small delay between launches is usually required for Hyprland to register the new window before dispatching a move
- The set of scripts is user-defined and grows as new domain layouts are established

Where scripts will live:
- User-level shell scripts; likely `~/.local/bin/bootstrap-domain-<N>` or a single script with a domain argument
- Tracked in the dotfiles repo (`~/.dotfiles`)

This feature is independent of the Kanata island. It can be implemented and used before any Kanata script-execution mode exists.

---

## Roadmap index

### Existing roadmap files
- `~/.config/opencode/ROADMAP.md` — OpenCode configuration, deferred fixes, and known bugs
- `~/.pi/ROADMAP.md` — Pi agent configuration, deferred fixes, and future features
- `~/.config/quickshell/ROADMAP.md` — Quickshell shell configuration bugs and features
- `~/nixos-config/docs/ROADMAP.md` — NixOS system configuration and operational tooling backlog

### Likely future roadmap homes
- `~/.config/hypr/ROADMAP.md` — if keybind, workspace, and window-management backlog grows
- `~/.config/ai/ROADMAP.md` — if the shared agent framework develops a larger future-work queue

---

## How to use this file

- keep this file high-level and cross-cutting
- when one area accumulates multiple deferred issues or planned features, create a local `ROADMAP.md` there and link it from here
- move stable architectural decisions into the most relevant `CONTEXT.md` or `MEMORY.md`
- keep session-specific implementation details in `memory/` notes instead of bloating this file
- cross-repo items are okay here when they directly affect the day-to-day dotfiles workflow
