# MEMORY.md — Neovim Config

## Current state

Plugins installed (LuaSnip, nvim-cmp, nvim-treesitter) but **snippet file is
broken and flagged for a full redo**. See session log for details.

## Cross-editor snippet strategy

**Do not design the LuaSnip setup in isolation.**

The canonical snippet data lives at:
`~/Repositories/self-hosted/zettelkasten/Documents/shortcuts.json`

This is the shared source of truth. Each editor has its own adapter that reads
from (or is derived from) that file:

| Target | Mechanism |
|---|---|
| Neovim | LuaSnip Lua adapter reads/translates shortcuts.json options |
| Obsidian | latex-suite or custom JS plugin |
| VSCodium | Converted to VS Code snippet JSON format |
| agent-display | CodeMirror 6 snippet system in `RichEditor.tsx` (Phase 2) |

**Options flag mapping** (from shortcuts.json):
- `t` = text mode only (no math condition)
- `m` = math mode only (`condition = in_math`)
- `A` = autosnippet
- `r` = regex trigger (`regTrig = true`)
- `w` = word boundary (`wordTrig = true`, the default)
- Combinations: `tA`, `mA`, `rmA` etc.

When redoing `lua/snippets/markdown.lua`, the goal is a Lua adapter that
correctly translates all these flags — not a standalone snippet file. Each
other editor will need its own thin adapter; the snippet data is the asset.

See also: `~/Repositories/projects/agent-display/project-memory/snippet-strategy.md`

## Active documents

- `CONTEXT.md` — orientation, file map, conventions
- `README.md` — human-readable docs and trigger reference
- `lua/snippets/markdown.lua` — full snippet source (broken, needs redo)

## Session logs

- [2026-04-28](memory/2026-04-28.md) — LuaSnip setup; snippet port from shortcuts.json; cross-editor strategy decided
