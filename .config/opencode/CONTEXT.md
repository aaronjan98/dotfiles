# OpenCode Configuration

## Overview
This directory contains the local OpenCode configuration for this machine.
It currently includes theme customization plus MCP server configuration for external tools like Context7 and Playwright.

## Directory Layout
```
~/.config/opencode/
├── CONTEXT.md          # This file - overview of OpenCode config
├── MEMORY.md           # Detailed learnings about theme configuration
├── tui.json           # TUI settings (theme, cursor style/blink)
├── opencode.json      # Runtime config (cursor options, MCP servers)
├── .gitignore        # Git ignore for node_modules
├── package.json      # NPM dependencies
├── themes/           # Custom theme files
│   └── raspberry.json
├── node_modules/      # NPM packages (ignored by git)
└── agents → /home/aj/.config/ai/agents/opencode  # Symlink to global agents config

~/.config/opencode → (same as above .config/opencode folder, not a symlink)
```

## Agent Setup Notes
- OpenCode config lives in `~/.config/opencode/` (not `~/.config/ai/opencode/)
- The `agents/` subdirectory is a symlink: `~/.config/opencode/agents → ~/.config/ai/agents/opencode`
- This shares agent configuration with global AI setup
- See `~/nixos-config/` for OpenCode NixOS package configuration

## Files
- `tui.json` - TUI configuration (theme selection, cursor settings)
- `opencode.json` - Runtime configuration (cursor settings, MCP servers)
- `themes/raspberry.json` - Custom theme

## Current Configuration

### tui.json
```json
{
  "theme": "raspberry",
  "cursor_style": "line",
  "cursor_blink": false
}
```

### opencode.json
```json
{
  "tui": {
    "cursor_color": "#FF2800",
    "cursor_style": "line",
    "cursor_blink": false
  }
}
```

## Theme Structure
Custom themes go in `~/.config/opencode/themes/<theme-name>.json`

The raspberry theme uses:
- **primary**: Ferrari Red `#FF2800` (for popup accents)
- **background**: `"none"` (transparent - inherits terminal background)
- **backgroundPanel**: `#2a1520` (raspberry - side panel color)
- **backgroundElement**: `#2a1520` (raspberry - input box color)
- **borders**: `"none"` (transparent)
- **orange replaced with**: Ferrari Red `#FF2800`

## MCP Notes
- `context7` is configured as a remote MCP and reads its API key from `CONTEXT7_API_KEY`
- `playwright` is configured as a local MCP started with `npx @playwright/mcp@latest --headless`
- secrets should not be stored in this directory; they should come from NixOS-managed runtime env vars

## Key Learnings
See MEMORY.md for detailed learnings about theme and MCP configuration.
