# CONTEXT.md

## Project
Pi local config

## Purpose
This directory stores the user-level configuration for the Pi coding agent.
It defines which providers and models Pi can use locally, plus the defaults that should be selected when Pi starts.
This directory is intended to be tracked in dotfiles, so secrets must not be written directly into the tracked config files.

## What good looks like
- Pi starts with sensible defaults and working model definitions
- tracked config is reproducible across machines
- secrets are referenced indirectly from runtime-managed paths rather than stored here
- future agents can quickly understand why the config is structured this way

## What to avoid
- storing API keys directly in `agent/models.json` or other tracked files
- assuming Pi was installed with npm when it is actually managed through NixOS
- changing provider definitions without understanding the API type they use
- leaving Pi-specific decisions only in chat instead of writing them here or in memory files

## Main directories
- `agent/` — Pi settings and provider/model definitions
- `memory/` — date-stamped Pi config session logs (YYYY-MM-DD.md)

## Important files
- `README.md` — human-facing overview of this config directory
- `agent/settings.json` — default provider/model/thinking level
- `agent/models.json` — custom provider definitions, especially OpenCode Zen
- `agent/mcp.json` — MCP servers exposed through `pi-mcp-adapter`
- `agent/extensions/default-tools.ts` — enables the richer built-in tool set on startup
- `agent/themes/transparent-dark.json` — custom theme that removes most block backgrounds
- `MEMORY.md` — loading manifest and durable Pi config notes
- `ROADMAP.md` — deferred issues and planned future improvements

## Working rules
- Treat this directory as tracked dotfiles-friendly config
- Keep secrets out of tracked files; reference `/run/secrets/...` instead when needed
- Prefer small config edits and preserve working providers unless there is a clear reason to change them
- When changing model/provider behavior, record the reason in `MEMORY.md` or `memory/YYYY-MM-DD.md`

## Workflow
1. Read `README.md`, `CONTEXT.md`, and `MEMORY.md`.
2. Inspect `agent/settings.json` or `agent/models.json` depending on the task.
3. Make the smallest useful change.
4. Record durable decisions in `MEMORY.md` and session work in `memory/YYYY-MM-DD.md`.
