# 2026-04-17 — Codex agent orientation setup

## What was worked on

Wired Codex CLI into the agent workspace system so it loads shared orientation on every session.

## How Codex loads instructions

- Codex reads `~/.codex/AGENTS.md` as its global instructions file (equivalent of CLAUDE.md).
- Also reads project-level `AGENTS.md` files, walking from git root to cwd, concatenating them.
- Controlled via `~/.codex/config.toml` (model, trust levels, sandbox, etc.).
- No `system_prompt` field in config.toml — AGENTS.md is the only global instruction mechanism.

## What was set up

- Created `~/.config/ai/agents/codex/AGENTS.md` — canonical source, mirrors CLAUDE.md structure.
- Symlinked to `~/.codex/AGENTS.md` so Codex picks it up automatically.
- Content: same bootstrap pattern as Claude — read agent-orientation.md, tool-commands.md,
  project CONTEXT/MEMORY/DEPENDENCIES, fall back to ROUTER.md.

## config.toml state

- `nixos-config` and `~/Repositories/projects` marked as `trust_level = "trusted"`.
