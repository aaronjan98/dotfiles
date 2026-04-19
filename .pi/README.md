# Pi config

This directory contains the local Pi coding agent configuration for this machine.

## Main files
- `agent/settings.json` — default provider, model, and thinking level
- `agent/models.json` — custom provider/model definitions
- `CONTEXT.md` — agent-facing overview for working in this directory
- `MEMORY.md` — agent loading manifest and durable notes for this config
- `memory/` — date-stamped session logs for Pi-related changes

## What should be tracked vs ignored
Track the human-authored config and agent notes:
- `README.md`
- `CONTEXT.md`
- `MEMORY.md`
- `memory/`
- `agent/settings.json`
- `agent/models.json`

Ignore runtime/generated state:
- `agent/auth.json`
- `agent/bin/`
- `agent/sessions/`

## Secret handling
This config does **not** store API keys directly.

For OpenCode Zen, Pi reads the runtime secret managed by `sops-nix` via:

`!cat /run/secrets/opencode_zen_api_key`

That keeps the secret out of:
- `~/.pi`
- tracked dotfiles
- shell startup files like `.bashrc`

## Why there are multiple Zen providers
OpenCode Zen exposes different API shapes for different model families, so Pi uses separate providers for:
- OpenAI chat-completions compatible models
- Anthropic messages compatible models
- OpenAI responses compatible models

## Update model
Pi itself is installed declaratively through the `nixos-config` repo as a locally pinned Nix package.

That means:
- do **not** update Pi here with `npm install -g`
- update the package through `~/nixos-config/scripts/update-pi.sh`
- then rebuild NixOS
