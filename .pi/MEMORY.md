# MEMORY.md

## Read on every session
- `CONTEXT.md` — project overview, file paths, and working rules
- `README.md` — human-facing explanation of the Pi config structure
- `ROADMAP.md` — deferred issues and future feature work
- `agent/AGENTS.md` — global Pi harness bootstrap loaded automatically by Pi

## Read when relevant
- `memory/YYYY-MM-DD.md` — prior Pi config session logs
- `agent/settings.json` — current default provider/model settings
- `agent/models.json` — provider definitions and model catalog
- `agent/mcp.json` — current MCP server configuration

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
- `~/.pi/agent/AGENTS.md` should remain a symlink to the canonical bootstrap file at `~/.config/ai/agents/pi/AGENTS.md`, matching the pattern used for other agent harnesses.
- OpenCode Zen credentials should be loaded from `/run/secrets/opencode_zen_api_key`, not stored in `~/.pi`.
- Context7 credentials should come from `CONTEXT7_API_KEY`, exported by `sops-nix` through NixOS.
- The Pi binary itself is installed declaratively through `~/nixos-config`, not via global npm.
- OpenCode Zen is split into multiple Pi providers because Pi needs different API adapters for chat-completions, anthropic-messages, and responses-style models.
- Current default startup model is `opencode-zen-gpt / gpt-5.4` with `medium` thinking.
- Pi packages are declared in `agent/settings.json` so missing extensions can be reinstalled automatically on another machine.
- On NixOS, Pi's npm package installs must use a writable prefix under `~/.pi/agent/npm`; using plain `npm install -g` against the Nix store fails.
- The current writable npm prefix is hardcoded to `/home/aj/.pi/agent/npm` via `npmCommand`; this assumes the username/path stays the same across machines. If that stops being true, replace it with a wrapper or another username-independent mechanism.
- `pi-mcp-adapter` provides Context7 and Playwright MCP access; `pi-web-access` adds web search/fetch capabilities.
- `agent/mcp.json` currently uses Context7 via `@upstash/context7-mcp` with `CONTEXT7_API_KEY` and Playwright via `@playwright/mcp --headless`.
- `agent/extensions/default-tools.ts` is used to enable the richer built-in tool set (`grep`, `find`, `ls`) at startup instead of relying on CLI flags each run.
- Pi's occasional opaque/tinted blocks come from theme background tokens, not from arbitrary model output. `transparent-dark` blanks `userMessageBg`, `customMessageBg`, `toolPendingBg`, `toolSuccessBg`, and `toolErrorBg` so the terminal background shows through.
- `mdCodeBlock` controls code block text color, not a separate background fill. If a code block still appears boxed, it is usually because it is rendered inside a tool/message block whose background token is set.
- Assistant thinking traces are rendered with italic markdown plus the `thinkingText` foreground color; there is no dedicated thinking background token. If the thinking area looks like a grey box, adjust `thinkingText` rather than looking for a hidden background color.
- Markdown blockquotes are also rendered italic by Pi, using `mdQuote` and `mdQuoteBorder`. If they look like grey highlighted boxes, adjust those foreground colors too; Pi does not provide a separate quote background token.
- Pi cannot select a different font just for thinking/quotes. Font choice and italic font rendering are controlled by the terminal emulator, not by Pi themes.

---

## Session log index
- [2026-04-19](memory/2026-04-19.md) — documented Pi config structure, secret handling, and Zen provider setup

---

## Rules
- Record stable Pi config decisions here.
- Record day-specific setup/debugging notes in `memory/YYYY-MM-DD.md`.
- Update this file when defaults or secret-loading patterns change.
