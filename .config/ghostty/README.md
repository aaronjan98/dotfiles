# Ghostty Configuration

General configuration for Ghostty terminal emulator.

## Terminal Basics

- Background: Dark plum (`1a0810`).
- Opacity: `0.85`.
- Shell Integration: Managed via default shell-integration-features.

## Cursor Animation

- Implementation: Custom GLSL shader (`shaders/cursor_smear.glsl`).
- Effect: Calculates a parallelogram "bridge" between current (`iCurrentCursor`) and previous (`iPreviousCursor`) positions.
- Color: Hardcoded to Ferrari Red (#FF2800) (`vec4(1.0, 0.157, 0.0, 1.0)`) for visibility with `0` hardware opacity.
- Timing: `0.12s` duration with cubic easing for a snappy feel.
- Antialiasing: 2-pixel smoothstep for crisp edges.
- Hardware Settings: `cursor-style = block` and `cursor-opacity = 0` to prevent double-rendering.

## Maintenance & Debugging

- Reload Configuration: `Ctrl + Shift + ,` (Linux).
- Error Handling: Ghostty disables shaders if the configuration file has parsing errors (e.g., unknown fields).
- Shader Logs: Run `ghostty --debug` to view GLSL compilation errors.

## Credits

- Shader logic adapted from [linkarzu/dotfiles-latest](https://github.com/linkarzu/dotfiles-latest) and [KroneCorylus/ghostty-shader-playground](https://github.com/KroneCorylus/ghostty-shader-playground).
