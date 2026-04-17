# 2026-04-17 — Terminal and Claude Code Notifications

## What was worked on

Set up a notification system so that long-running commands (in tmux or direct Ghostty windows)
and completed Claude Code tasks surface as desktop toasts via Quickshell.

## Key insights

- Quickshell IS the notification daemon — it implements `org.freedesktop.Notifications` via DBus.
  Standard `notify-send` routes through it automatically. No extra integration needed on the
  Quickshell side.
- Ghostty 1.3.1 has a native `notify-on-command-finish` feature (since 1.3.0) that works via
  shell integration / OSC 133. Works out of the box for direct Ghostty windows.
- OSC 133 sequences emitted by Ghostty's bash integration are swallowed by tmux — they do NOT
  pass through to Ghostty even with `allow-passthrough on`, because Ghostty's integration does
  not wrap them in the DCS passthrough format (`\ePtmux;...\e\\`) when `$TMUX` is set.
  The fix for tmux is a direct `notify-send` call from PROMPT_COMMAND.
- `zoxide init bash` produces `PROMPT_COMMAND='__zoxide_hook;'` with a trailing semicolon.
  Appending with `; _ntfy_done` causes `;;` which is a bash syntax error. Fixed by using
  `PROMPT_COMMAND+=$'\n_ntfy_done'` (newline separator) with an idempotency guard.

## Decisions

- Ghostty config: `notify-on-command-finish = unfocused`, `notify-on-command-finish-action = no-bell,notify`, `notify-on-command-finish-after = 10s`
- tmux (modules/tmux.nix): added `set -g allow-passthrough on` for general OSC passthrough support
- ~/.bashrc: DEBUG trap + PROMPT_COMMAND hook for tmux panes only (`[[ -n "$TMUX" ]]` guard)
- Claude Code Stop hook: fires `notify-send` only when Ghostty is NOT the active Hyprland window
  (`hyprctl activewindow | grep -qi 'class: ghostty' || notify-send ...`)

## Files changed

- `~/.config/ghostty/config` — 3 notify lines added (dotfiles repo)
- `~/.bashrc` — PROMPT_COMMAND hook appended (dotfiles repo)
- `~/nixos-config/modules/tmux.nix` — `allow-passthrough on` added (requires `nrs`)
- `~/.claude/settings.json` — Stop hook added

## Open questions

- Does Ghostty's bash integration detect `$TMUX` and wrap OSC 133 in a future version?
  If so, `notify-on-command-finish` would work natively in tmux panes too, making the
  PROMPT_COMMAND hook redundant.

## Next steps

- Run `nrs` to apply the tmux passthrough change
- Test: run a command ≥10s in a tmux pane, switch to another window, verify toast appears
- Test: run a command in a direct Ghostty window (no tmux), verify Ghostty's native feature fires
- See `~/.config/quickshell/project-memory/notifications.md` for remaining planned integrations
  (Pushbullet, email, download completion, UI action buttons)

---

## Follow-up (same session)

### Problem
Notifications were firing even when the user stayed in the pane where the command ran.

### Root cause
`_ntfy_done` in `~/.bashrc` only checked `[[ -n "$TMUX" ]]` — no focus or pane-visibility check.
The Claude Code Stop hook only checked Ghostty window focus, not whether the active tmux pane
was the one running Claude.

### Fix
Both now suppress if **all three** are true: Ghostty is focused AND `pane_active=1` AND
`window_active=1` (via `tmux display-message -p '#{pane_active}#{window_active}'`).
Notification fires if any one is false.

### Files updated
- `~/.bashrc` — added pane/window/focus guard to `_ntfy_done`
- `~/.claude/settings.json` — added tmux pane check to Stop hook command

### Also done
- Added agent scaffolding to `~/.config/quickshell/`: `CONTEXT.md`, `MEMORY.md`, `memory/`,
  `project-memory/notifications.md` — integration checklist with Pushbullet, email, etc.
