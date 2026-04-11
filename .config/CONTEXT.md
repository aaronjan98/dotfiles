# ~/.config — Area Context

## Overview

User config directory. Tracked selectively via a bare git repo at `~/.dotfiles` using the `dot` alias (not `git` or `g`). Files and directories are spread across the system — this is the primary area agents should use to find terminal, editor, WM, and AI configuration.

See `~/.config/ai/shared/tool-commands.md` for how to determine whether a given file is tracked by dotfiles.

---

## Key Directories for Agent Work

| Directory | Purpose | State |
|---|---|---|
| `ai/` | Agent configuration, shared rules, skills, model routing | Active |
| `ghostty/` | Ghostty terminal emulator — config, GLSL cursor shader | Active |
| `nvim/` | Neovim configuration | Active |
| `tmux/` | tmux configuration | Active |
| `hypr/` | Hyprland WM configuration | Active |
| `fuzzel/` | App launcher configuration | Maintained |
| `kitty/` | Kitty terminal (secondary/backup terminal) | Maintained |
| `lazygit/` | Lazygit configuration | Maintained |
| `git/` | Git global configuration | Maintained |
| `quickshell/` | Quickshell widget/shell configuration | Active |
| `btop/` | btop system monitor theme/config | Maintained |
| `systemd/` | User systemd units | Maintained |

Directories not listed (KDE/Plasma system files, app data dirs, etc.) are system-managed and not relevant for agent work unless explicitly asked.

---

## Individually Tracked Files

Some files at the root of `~/.config/` are tracked directly (not as part of a subdirectory):

| File | Purpose |
|---|---|
| `mimeapps.list` | XDG default application associations. Gwenview is set for all image types. Do not set eog — it is not installed on this system. |
| `okularpartrc` | Okular document viewer settings. `ChangeColors=false` is intentional — the recolor mode was causing a red overlay on all images. |

---

## Notes

- Do not use `git` or `g` for dotfiles — always use `dot`.
- Each actively maintained subdirectory should have its own `CONTEXT.md` for agent orientation.
- **Staging gotcha:** the dotfiles work tree is `$HOME`, not `~/.config/`. When running `dot add` from inside `~/.config/`, use absolute paths (`/home/aj/.config/...`) or git will double-nest the path and fail. See `ai/shared/tool-commands.md` for details.
