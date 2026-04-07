# Ghostty Configuration

General configuration for Ghostty terminal emulator.

## Terminal Basics

- Background: Dark plum (`1a0810`).
- Opacity: `0.85`.
- Shell Integration: Managed via default shell-integration-features.

## Cursor Animation

Cursor rendering is split: Ghostty owns the cursor block; the shader owns the smear trail.

**Ghostty (native):**
- `cursor-style = block`, `cursor-style-blink = true`, `cursor-color = #FF2800`, `cursor-text = #000000`
- Handles blinking and character inversion (black text on red cursor block).

**Shader (`shaders/cursor_smear.glsl`):**
- Draws a parallelogram "bridge" between `iPreviousCursor` and `iCurrentCursor` positions.
- Trail color: Ferrari Red (`#FF2800`), duration `0.12s`, cubic ease-out.
- Does NOT touch the cursor block itself — Ghostty pre-renders the cursor into `iChannel0` before the shader runs, making the character underneath inaccessible. Attempting cursor inversion in the shader produces incorrect results (inverting the cursor color, not the character).

## Maintenance & Debugging

- Reload Configuration: `Ctrl + Shift + ,` (Linux).
- Error Handling: Ghostty disables shaders if the configuration file has parsing errors (e.g., unknown fields).
- Shader Logs: Run `ghostty --debug` to view GLSL compilation errors.

## Credits

- Shader logic adapted from [linkarzu/dotfiles-latest](https://github.com/linkarzu/dotfiles-latest) and [KroneCorylus/ghostty-shader-playground](https://github.com/KroneCorylus/ghostty-shader-playground).
