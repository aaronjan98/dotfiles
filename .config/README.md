# dotfiles

Configuration for a Hyprland desktop on NixOS. Managed as a bare git repo (`~/.dotfiles`) with the work tree at `~/.config/`.

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
| `ai/` | Agent-first AI workspace — shared rules, skills, and model routing for Claude and Gemini |
| tmux | Managed in NixOS config — see [`modules/tmux.nix`](https://github.com/aaronjan98/nixos-config/blob/main/modules/tmux.nix) |

---

## Highlights

### Ghostty cursor shader

A custom GLSL post-processing shader draws a parallelogram smear trail between the cursor's previous and current positions. Cursor block rendering (blink, character inversion) is delegated to Ghostty natively; the shader handles only the motion trail. Source: [`ghostty/shaders/cursor_smear.glsl`](ghostty/shaders/cursor_smear.glsl).

### Quickshell — limerence rice

A modular, multi-theme Quickshell setup where each "rice" is a fully self-contained QML configuration. Theme switching is done via symlink (`rices/current`) with no config edits required. The active rice (*limerence*) includes a top bar, left bar, notification center, and system service integrations (Wi-Fi, volume, battery, brightness, Bluetooth). See [`quickshell/rices/limerence/docs/`](quickshell/rices/limerence/docs/).

### Hyprland workspace scripts

Custom shell scripts in `hypr/scripts/` implement a slot-based workspace model: workspaces are organized into named domains, and scripts handle relative navigation, slot assignment, and cross-monitor movement.

### AI agent framework

`ai/` is a file-first framework for running AI agents (Claude, Gemini) against this config and other local projects. It defines shared principles, model routing rules, memory conventions, and reusable skills (session saving, zettelkasten search, notebook inspection, etc.). Agents read `CONTEXT.md` files to orient themselves before acting.

---

## Setup

This repo uses the bare git + work tree method. To clone onto a new machine:

```bash
git clone --bare git@github.com:aaronjan98/dotfiles.git ~/.dotfiles
alias dot='git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME/.config"'
dot checkout
```

Package management is handled separately via NixOS — see [aaronjan98/nixos-config](https://github.com/aaronjan98/nixos-config). This repo tracks only configuration files.
