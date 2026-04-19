# MEMORY.md

## Read on every session
- `CONTEXT.md` — project overview, file paths, and working rules
- `README.md` — human-facing explanation of the Pi config structure

## Read when relevant
- `memory/YYYY-MM-DD.md` — prior Pi config session logs
- `agent/settings.json` — current default provider/model settings
- `agent/models.json` — provider definitions and model catalog

## Reference only
- `~/nixos-config/docs/PACKAGES.md` — how Pi is packaged and updated via Nix
- `~/nixos-config/docs/SECRETS.md` — how runtime secrets under `/run/...` are managed
- `~/nixos-config/docs/SCRIPTS.md` — `update-pi.sh` workflow

## Not for agents
- do not write secrets into this directory
- do not assume chat history is persistent memory

---

## Durable notes
- Pi config in this directory is intended to be tracked in dotfiles.
- OpenCode Zen credentials should be loaded from `/run/secrets/opencode_zen_api_key`, not stored in `~/.pi`.
- The Pi binary itself is installed declaratively through `~/nixos-config`, not via global npm.
- OpenCode Zen is split into multiple Pi providers because Pi needs different API adapters for chat-completions, anthropic-messages, and responses-style models.
- Current default startup model is `opencode-zen-gpt / gpt-5.4` with `medium` thinking.

---

## Session log index
- [2026-04-19](memory/2026-04-19.md) — documented Pi config structure, secret handling, and Zen provider setup

---

## Rules
- Record stable Pi config decisions here.
- Record day-specific setup/debugging notes in `memory/YYYY-MM-DD.md`.
- Update this file when defaults or secret-loading patterns change.
