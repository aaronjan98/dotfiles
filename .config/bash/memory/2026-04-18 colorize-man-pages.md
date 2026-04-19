# 2026-04-18 — Colorize man pages

## What was worked on
Set up colorized man pages following Dave Eddy's approach (YouTube: @yousuckatprogramming, gist: bahamas10/542875bb47990933638d2b7dfaa501bf).

Created `~/.config/bash/man-color.sh` as a sourced snippet from `~/.bashrc`.

## Key decisions
- Placed snippet in `~/.config/bash/` (XDG-style) rather than home root, to keep `$HOME` tidy
- Used raw ANSI escape codes (`$'\e[...]'`) instead of `tput` — simpler, no subprocess overhead, universally supported on modern terminals
- Added guarded source block in `.bashrc` (same pattern as `.bash_aliases`)

## Key insight — GROFF_NO_SGR is required
The `LESS_TERMCAP_*` variables were being ignored because modern groff outputs SGR (ANSI) escape sequences directly. When that happens, `less -R` passes them through as-is and never consults the termcap variables.

Setting `export GROFF_NO_SGR=1` forces groff to output old-style overstrike formatting (char + backspace + char), which `less` then translates using the `LESS_TERMCAP_*` variables.

This was the root cause — not Ghostty, not tmux, not the escape code syntax.

## Additional exports needed
- `export LESS=-R` — tells less to interpret ANSI escape sequences
- `export MANPAGER='less'` — ensures man uses less (usually default, but explicit)
- `export GROFF_NO_SGR=1` — the critical fix

## Files created/modified
- Created: `~/.config/bash/man-color.sh`
- Modified: `~/.bashrc` (added source block near top)

## Color scheme
- Bold/blink: bold red (`1;31`)
- Section headers (bold): bold red (`1;31`)
- Search highlights (standout): bold yellow on blue (`1;33;44`)
- Underlined text: bold green underline (`4;1;32`)
- Reverse video: `7`
- Dim: `2`

## Open questions
- None

## Next steps
- None — feature complete