# CONTEXT.md — Neovim Config

## What this is

Personal Neovim configuration. Intentionally minimal: only plugins that are
actively used. Not a full IDE setup.

## Current state

Active and maintained. Plugin stack as of 2026-04-28:
- `lean.nvim` — Lean 4 (primary use case for Neovim)
- `vim-tmux-navigator` — split/pane navigation
- `LuaSnip` + `nvim-cmp` + `nvim-treesitter` — math snippet system for markdown

## Snippet system

Snippets are ported from the user's Obsidian latex-suite shortcuts
(`~/Repositories/self-hosted/zettelkasten/Documents/shortcuts.json`).

- Source format: Obsidian latex-suite JSON
- Target format: LuaSnip `from_lua` loader (`lua/snippets/markdown.lua`)
- Math context detection: treesitter with `$`-count fallback
- Skipped: JS function snippets, Obsidian macro variables

## Key files

| File | Purpose |
|------|---------|
| `init.lua` | Entry point |
| `lua/lazy_setup.lua` | Plugin manager bootstrap |
| `lua/core/options.lua` | Editor options |
| `lua/core/keymaps.lua` | Global keymaps (buffer nav, pane nav, save) |
| `lua/plugins/lean.lua` | Lean 4 plugin spec |
| `lua/plugins/tmuxnav.lua` | Tmux navigator plugin spec |
| `lua/plugins/luasnip.lua` | LuaSnip + cmp + treesitter plugin specs |
| `lua/snippets/markdown.lua` | Markdown math/text snippets |

## Conventions

- Plugins declared as lazy.nvim specs in `lua/plugins/*.lua`
- Snippets per-filetype in `lua/snippets/<filetype>.lua`
- No LSP configured (Lean handles its own via lean.nvim)
- No formatter configured
- Neovide-specific settings in `init.lua`

## What NOT to add without asking

- Global LSP setup (conflicts with lean.nvim's self-managed LSP)
- Aggressive text object plugins (user prefers minimal)
- Status line replacements (uses default)
