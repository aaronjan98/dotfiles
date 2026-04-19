# CONTEXT.md

## Project
bash-config

## Purpose
Custom bash configuration snippets sourced from `~/.bashrc`. Each file in this directory is a self-contained configuration module that `~/.bashrc` sources via an `if [ -f ... ]; then . ...; fi` guard.

This keeps `.bashrc` clean and lets each concern live in its own file.

## What good looks like
- each snippet is a standalone, well-commented file
- sourcing order doesn't matter between snippets (no inter-dependencies)
- environment variables and functions have clear documentation
- changes are committed via `dot` (dotfiles bare repo)

## What to avoid
- putting interactive shell logic here that belongs in `.bashrc` itself
- creating dependencies between snippets
- duplicating things already handled by NixOS system configuration

## Files
- `man-color.sh` — colorized man pages via LESS_TERMCAP variables and GROFF_NO_SGR

## Main directories
- `memory/` — date-stamped session logs

## Working rules
- This directory is tracked by the dotfiles bare repo (`dot`), not regular git.
- New snippets should follow the same pattern: exports and comments, no side effects.
- Always test with `source ~/.bashrc` after changes.