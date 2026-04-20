# dotfiles

Configuration for a Hyprland desktop on NixOS. Managed as a bare git repo (`~/.dotfiles`) with the work tree at `$HOME`.

---

## What's here

| Directory | Description |
|---|---|
| `hypr/` | Hyprland compositor — keybinds, env vars, appearance, custom workspace scripts |
| `ghostty/` | Ghostty terminal — dark plum theme, custom GLSL cursor smear shader |
| `nvim/` | Neovim config (lazy.nvim) — Lean.nvim for theorem proving, tmux navigation |
| `quickshell/` | Quickshell status shell — multi-rice system, active rice: *limerence* |
| `kitty/` | Kitty terminal — fonts, colors, keybindings |
| `fuzzel/` | Fuzzel app launcher config |
| `firefox/` | Firefox `userChrome.css` — transparent toolbar/tabs via Wayland compositor blur |
| `ai/` | Agent-first AI workspace — shared rules, skills, and model routing for Claude and Gemini |
| `.pi/` | Pi coding agent config — tracked settings/models plus agent notes; runtime auth/session state intentionally ignored |
| tmux | Managed in NixOS config — see [`modules/tmux.nix`](https://github.com/aaronjan98/nixos-config/blob/main/modules/tmux.nix) |

High-level deferred work is tracked in [`.config/ROADMAP.md`](.config/ROADMAP.md), which links out to more specific roadmap files like `~/.pi/ROADMAP.md` and adjacent system-level backlog notes.

---

## Highlights

### Ghostty cursor shader

A custom GLSL post-processing shader draws a parallelogram smear trail between the cursor's previous and current positions. Cursor block rendering (blink, character inversion) is delegated to Ghostty natively; the shader handles only the motion trail. Source: [`.config/ghostty/shaders/cursor_smear.glsl`](.config/ghostty/shaders/cursor_smear.glsl).

### Quickshell — limerence rice

A modular, multi-theme Quickshell setup where each "rice" is a fully self-contained QML configuration. Theme switching is done via symlink (`rices/current`) with no config edits required. The active rice (*limerence*) includes a top bar, left bar, notification center, and system service integrations (Wi-Fi, volume, battery, brightness, Bluetooth). See [`.config/quickshell/rices/limerence/docs/`](.config/quickshell/rices/limerence/docs/).

### Hyprland workspace scripts

Custom shell scripts in `.config/hypr/scripts/` implement a slot-based workspace model: workspaces are organized into named domains, and scripts handle relative navigation, slot assignment, and cross-monitor movement.

### AI agent framework

`.config/ai/` is a file-first framework for running AI agents (Claude, Gemini) against this config and other local projects. It defines shared principles, model routing rules, memory conventions, and reusable skills (session saving, zettelkasten search, notebook inspection, etc.). Agents read `CONTEXT.md` files to orient themselves before acting.

### Pi coding agent config

`~/.pi/` stores tracked Pi configuration and agent notes while leaving runtime state out of the repo. Human-authored files like `agent/settings.json`, `agent/models.json`, `CONTEXT.md`, `MEMORY.md`, and `memory/` are tracked; generated files like `agent/auth.json`, `agent/bin/`, and `agent/sessions/` are intentionally ignored.

OpenCode Zen credentials are not stored in dotfiles. Pi reads the runtime secret from `/run/secrets/opencode_zen_api_key`, which is provisioned separately by the NixOS `sops-nix` setup in [`aaronjan98/nixos-config`](https://github.com/aaronjan98/nixos-config).

---

## Setup

This repo uses the bare git + work tree method. To clone onto a new machine:

```bash
git clone --bare git@github.com:aaronjan98/dotfiles.git ~/.dotfiles
alias dot='git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'
dot checkout
```

Package management is handled separately via NixOS — see [aaronjan98/nixos-config](https://github.com/aaronjan98/nixos-config). This repo tracks configuration and selected agent-facing notes, but not runtime auth/session/cache state.

### Firefox profile path

`userChrome.css` is tracked under a profile-specific path (e.g. `zpqkr59d.default`) which Firefox generates randomly per installation. On a new machine, `dot checkout` will place the file under the old profile name — you'll need to copy it manually to the new profile directory. Find the correct path via `about:support` → *Profile Directory*.

Also required in `about:config`:
- `toolkit.legacyUserProfileCustomizations.stylesheets` → `true`
- `widget.gtk.transparent-background` → `true`
