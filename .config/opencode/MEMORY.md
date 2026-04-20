# OpenCode Configuration Knowledge

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

### Current MCPs
- `context7` — remote docs lookup, authenticated via `CONTEXT7_API_KEY`
- `playwright` — local browser automation via `npx @playwright/mcp@latest`

### Known Issues
- **Database migration runs every launch**: Known OpenCode bug (#16885) - migration runs on every start even though it's supposed to be "one-time". This is an upstream issue, not config-related.

## Detailed Learnings
See `memory/` directory for full session notes:
- `memory/2026-04-18 raspberry-theme.md` - Theme customization session
- `memory/2026-04-19 mcp-setup.md` - Context7 and Playwright MCP setup

## Configuration Locations
- `tui.json` - Theme selection, cursor style/blink
- `opencode.json` - Runtime options plus MCP server configuration
- `themes/raspberry.json` - Custom theme file

## Useful Commands
- `/themes` - Switch theme
- `opencode debug config` - Debug configuration
- `opencode mcp list` - List MCP servers and auth status
- `opencode mcp auth <server>` - Authenticate an OAuth-capable remote MCP when needed
