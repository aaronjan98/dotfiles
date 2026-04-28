# Neovim Configuration

Personal Neovim config. Minimal by design — only adds what is actively used.

## Plugin manager

[lazy.nvim](https://github.com/folke/lazy.nvim) — bootstrapped in `lua/lazy_setup.lua`.

## Plugins

| Plugin | Purpose |
|--------|---------|
| `lean.nvim` | Lean 4 language support |
| `vim-tmux-navigator` | Seamless navigation across Neovim splits and tmux panes |
| `L3MON4D3/LuaSnip` | Snippet engine with auto-trigger and math context support |
| `hrsh7th/nvim-cmp` | Completion menu (sources: snippets, buffer) |
| `nvim-treesitter` | Syntax tree parsing; used for math context detection in markdown |

## Snippets

Snippets live in `lua/snippets/markdown.lua` and are loaded by LuaSnip's `from_lua` loader.
They are ported from `~/Repositories/self-hosted/zettelkasten/Documents/shortcuts.json`
(Obsidian latex-suite format).

**Skipped from port:**
- JavaScript function replacements (`pa*`, `iden`, `arr_`)
- Obsidian macro variables (`${GREEK}`, `${SYMBOL}`, `${VISUAL}`)
- Overly broad text abbreviations

### Math context

Math-mode snippets fire only when the cursor is inside a `$...$` or `$$...$$` block.
Detection uses treesitter node types (`inline_formula`, `math_environment`,
`displayed_formula`) with a `$`-count fallback.

### Key triggers

| Trigger | Result | Mode |
|---------|--------|------|
| `mk` | `$│$` inline math | global auto |
| `dm` | `$$\n│\n$$` display math | global auto |
| `//` | `\frac{│}{│}` | math auto |
| `sr` / `cb` | `^2` / `^3` | math auto |
| `@a`–`@O` | Greek letters (`\alpha`–`\Omega`) | math auto |
| `xhat` / `xvec` / `xbar` | `\hat{x}` / `\vec{x}` / `\bar{x}` | math auto (regex) |
| `x2` | `x_{2}` | math auto (regex) |
| `x--` | `x^{-1}` | math auto (regex) |
| `def.` / `thm.` / `lemm.` | Bold theorem headers | global auto |
| `\int` / `\sum` / `\lim` | Expanded with limits | math auto |
| `beg` | `\begin{align│}…\end{align│}` | math auto |
| `pmat` / `bmat` / `cases` | Matrix/case environments | math Tab |

### Keymaps

| Key | Action |
|-----|--------|
| `<Tab>` | Expand snippet or jump to next tabstop |
| `<S-Tab>` | Jump to previous tabstop |
| `<C-n>` / `<C-p>` | Select next/prev completion item |
| `<C-y>` | Confirm completion |
| `<C-e>` | Abort completion |

## File layout

```
~/.config/nvim/
├── init.lua                  entry point
├── lua/
│   ├── lazy_setup.lua        plugin manager bootstrap
│   ├── core/
│   │   ├── options.lua       editor options
│   │   └── keymaps.lua       global keymaps
│   ├── plugins/
│   │   ├── lean.lua          Lean 4
│   │   ├── tmuxnav.lua       tmux navigator
│   │   └── luasnip.lua       LuaSnip + cmp + treesitter
│   └── snippets/
│       └── markdown.lua      math/text snippets for .md files
├── CONTEXT.md
├── MEMORY.md
└── memory/
```
