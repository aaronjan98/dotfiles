# OpenCode Theme Knowledge

## Quick Reference

### Current Theme
- **Theme**: raspberry
- **Primary Color**: Ferrari Red `#FF2800`
- **Background**: transparent (main window)
- **Panel Colors**: raspberry `#2a1520`
- **Cursor**: line style, non-blinking

### Important Gotchas
- **cursor_color config**: Not yet deployed in schema - silently ignored
- **No separate cursor color key**: Must use `text` color (affects ALL text)
- **Transparency**: Use `system` theme only - custom themes don't support it well
- **Alpha colors**: 8-digit hex NOT supported

## Detailed Learnings
See `memory/` directory for full session notes:
- `memory/2026-04-18 raspberry-theme.md` - Theme customization session

## Configuration Locations
- `tui.json` - Theme selection, cursor style/blink
- `opencode.json` - Runtime options (cursor_color not working yet)
- `themes/raspberry.json` - Custom theme file

## Useful Commands
- `/themes` - Switch theme
- `opencode debug config` - Debug configuration
