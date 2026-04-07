# Ghostty Configuration — Context

## Overview

Ghostty terminal emulator configuration. Tracked in dotfiles (`dot` alias).

Key files:
- `config` — main Ghostty config (background, cursor, opacity, shader path)
- `shaders/cursor_smear.glsl` — custom GLSL post-processing shader
- `README.md` — human-readable documentation

---

## Architecture

Cursor rendering is split across two layers:

**Ghostty (native):**
- Renders the cursor block with color `#FF2800` (Ferrari Red) and `cursor-style-blink = true`
- Handles character inversion inside the cursor block (`cursor-text = #000000`)
- Ghostty's rendered frame (including the cursor) is passed to the shader as `iChannel0`

**Shader (`cursor_smear.glsl`):**
- Handles the smear/trail effect only — a parallelogram bridging previous and current cursor position
- Does NOT render or invert the cursor block itself (attempting this fails because `iChannel0` contains Ghostty's already-rendered cursor, making character content inaccessible to the shader)
- Trail color matches cursor color: `#FF2800`
- Trail duration: 0.12s with cubic ease-out

**Why the shader doesn't own the cursor:**
Ghostty pre-renders the cursor into `iChannel0` before the shader runs. The character under the cursor is not separately accessible. Any attempt to invert the cursor in the shader operates on Ghostty's already-drawn cursor block, not the character behind it.

---

## Debugging

- Reload config: `Ctrl+Shift+,`
- GLSL errors: `ghostty --debug`
- Ghostty silently disables the shader on parse errors (unknown config fields also trigger this)

---

## Memory

Session notes: `memory/`
