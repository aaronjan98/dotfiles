# 2026-04-07 — Ghostty cursor shader debugging

## What was worked on

Debugging why the cursor block in Ghostty + tmux showed no character underneath it (just a solid red block), and fixing the cursor smear shader.

## Key Findings

**Root cause:** Ghostty pre-renders the cursor into `iChannel0` before the custom shader runs. The character underneath the cursor is NOT separately accessible to the shader. This makes it impossible for a shader to "look through" the cursor and invert the character — the shader only sees the cursor block color.

**Why `cursor-opacity = 0` didn't fix it:** Setting opacity to 0 made the cursor invisible in the final render, but Ghostty still pre-rendered the cursor into `iChannel0`. The character was missing or obscured at that cell position, causing the shader's inversion formula to compute against background color → solid red output.

**Why removing `cursor-opacity = 0` caused red/green blinking:** With the cursor baked into `iChannel0` as `#FF2800` (red), the old inversion formula `TRAIL_COLOR * (1 - terminalColor)` computed `RED * (1 - RED) = (0, 0.13, 0)` = dark green on the "blink on" phase.

## Decisions

- **Removed cursor rendering from the shader entirely.** The shader now handles only the parallelogram smear trail.
- **Delegated cursor block rendering to Ghostty natively:** `cursor-style-blink = true`, `cursor-color = #FF2800`, `cursor-text = #000000` (black text inside red cursor).
- **Removed `cursor-opacity = 0`** — no longer needed since the shader doesn't need raw character access.

## Final Config State

```
cursor-style = block
cursor-style-blink = true
cursor-color = #FF2800
cursor-text = #000000
custom-shader = .../cursor_smear.glsl
```

Shader: trail-only. No cursor inversion logic.

## Open Questions

- The inactive pane cursor in tmux shows the character with reverse attributes — this is tmux's own inactive cursor rendering, independent of Ghostty. Behavior is correct.
- `cursor-text = #000000` (black) chosen for contrast. If font weight makes it hard to read, try `#ffffff`.
