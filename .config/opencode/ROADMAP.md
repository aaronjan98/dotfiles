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
