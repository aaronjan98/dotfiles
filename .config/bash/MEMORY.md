# MEMORY.md

## Read on every session
- `CONTEXT.md` — directory overview and working rules

## Read when relevant
- `memory/YYYY-MM-DD topic.md` — session logs

## Durable notes
- Snippets are sourced from `~/.bashrc` via guarded `. "$HOME/.config/bash/<file>"` blocks
- This directory is tracked by the dotfiles bare repo (`dot`)
- `GROFF_NO_SGR=1` is required for `LESS_TERMCAP_*` colors to work — without it, groff outputs its own SGR codes and less ignores the custom termcap variables
- `LESS=-R` is required so less interprets ANSI escape sequences

## Session log index
- [2026-04-18 colorize-man-pages](memory/2026-04-18 colorize-man-pages.md) — set up colorized man pages via LESS_TERMCAP

## Rules
- Do not leave important decisions only in chat — write them here or in memory/.
- Keep this file as a loading manifest, not a dump of facts.