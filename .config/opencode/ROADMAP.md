# ROADMAP.md

This file tracks deferred fixes, known bugs, and future configuration work for OpenCode.

## Known Issues

### Database migration runs on every launch
Status: deferred (upstream bug)

Problem:
- The message "Performing one time database migration" appears on every `opencode` invocation
- Migration takes several seconds each time
- Log shows: `applying migrations` runs on every launch

Root cause:
- OpenCode uses the "stable" channel which creates `opencode-stable.db`
- The migration gate check hardcodes `opencode.db` (known issue #16885)
- This causes the migration to re-run because the check fails for channel-specific DBs

Affected:
- Version: 1.4.6 (NixOS unstable)
- Channel: stable (uses `opencode-stable.db`)
- Upstream issue: anomalyco/opencode#16885

Workaround:
- None available yet - waiting for upstream fix
- This is NOT caused by MCP configuration changes
- The Playwright `--browser` args were removed coincidentally but did not affect this

### Default model falls back to removed ollama model on launch
Status: deferred (needs config fix)

Problem:
- On every launch, opencode defaults to `glm flash` (or similar) from ollama, which is no longer installed
- Requires manually switching to the desired model each session

Root cause:
- opencode persists the last-used or configured model; the ollama model is likely still set in `opencode.json` or in the DB as the preferred default
- Ollama is not running / the model no longer exists locally, but opencode tries it anyway

Fix:
- Check `~/.config/opencode/opencode.json` for a hardcoded model or provider setting
- Either remove/update the model entry, or set an explicit default pointing to the correct provider (e.g. Anthropic claude-sonnet-4-6)

## Future Features

### Live runtime theme switching
Goal:
- Support theme switching without restarting OpenCode

Open questions:
- Whether this requires upstream support or can be done via config reload
- See also: `~/.config/ROADMAP.md` for cross-app theme switching plans

## How to use this file
- add deferred issues that are known but intentionally not fixed yet
- add feature ideas that should survive beyond a single chat session
- move stable architectural decisions into `MEMORY.md`
- keep day-specific implementation details in `memory/YYYY-MM-DD.md`
