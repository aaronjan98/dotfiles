# Notification Integration Checklist

The Quickshell notification daemon receives any `notify-send` / libnotify call via DBus
(`org.freedesktop.Notifications`). For the notification subsystem architecture, see
`rices/limerence/docs/notifications.md` before touching any of these files.

## Already working (as of 2026-04-17)

- [x] **tmux pane command completion** — `notify-send` via PROMPT_COMMAND hook in `~/.bashrc`
  (commands ≥ 10s, tmux-only; skipped for direct Ghostty windows)
- [x] **Direct Ghostty window command completion** — native `notify-on-command-finish = unfocused`
  in `~/.config/ghostty/config` (requires shell integration, already auto-injecting)
- [x] **Claude Code task completion** — Stop hook in `~/.claude/settings.json`,
  suppressed when Ghostty is the active window (`hyprctl activewindow` check)

## Planned

### Phone / browser
- [ ] **Pushbullet** — mirror phone notifications to desktop
  - Bridge: systemd user service connecting to Pushbullet streaming WebSocket → `notify-send`
  - Candidates: a small Python/Node service or an existing tool like `pb-for-desktop`
  - Stretch: wire `NotificationToast.qml` action buttons to reply back via Pushbullet API
  - Note: `NotifsIpc.qml` exposes `invoke(nid, key)` which could dispatch the reply

### Email
- [ ] **Email arrival notifications**
  - Clarify mail setup before implementing (mbsync? aerc? neomutt?)
  - If `mbsync`: post-sync hook → `notify-send`
  - If a TUI client: use its built-in new-mail hook

### System / CLI tools
- [ ] **Download completion** (Motrix, `yt-dlp`, long `rsync`)
  - Motrix: verify its built-in notification actually routes through DBus correctly
  - CLI tools: PROMPT_COMMAND / shell alias pattern, same approach as tmux hook

### Quickshell UI improvements
- [ ] **Verify app icons render** in `NotificationToast.qml` for custom `--app-name` senders
  (terminal, claude-code) — the icon logic exists, needs real-world testing
- [ ] **"Focus tmux window" action button** — notification action that calls
  `tmux switch-client -t <session:window>` to jump to the relevant pane
