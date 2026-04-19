# ROADMAP.md

This file tracks deferred fixes, design ideas, and future feature work for the Pi setup in this directory.

## Ongoing issues

### Thinking / quote rendering looks like it has a background
Status: deferred

Problem:
- Pi renders assistant thinking traces and markdown blockquotes in italic text
- in the current terminal/font setup, that styling can look like it has a grey or tinted background even when Pi theme background tokens are transparent

What was learned:
- this is not primarily controlled by Pi background theme tokens
- thinking traces are styled via `thinkingText` + italics
- blockquotes are styled via `mdQuote` / `mdQuoteBorder` + italics
- Pi does not support changing fonts per message type

Current decision:
- do not patch Pi for now
- do not hide/collapse thinking for now
- live with the current rendering behavior unless it becomes more annoying

Possible future approaches:
- revisit terminal font or italic rendering configuration
- patch Pi to stop italicizing thinking and/or blockquotes
- upstream a configurable option if Pi later supports non-italic thinking/quote rendering

## Future features

### Subagents
Goal:
- make Pi more capable of delegating focused tasks to smaller/specialized units of work, closer to richer agent harnesses

Open questions:
- whether this should be done via Pi extensions, prompt conventions, MCP-backed tools, or upstream Pi features
- how to keep the workflow reproducible through dotfiles/NixOS rather than ad-hoc runtime setup

### Planning mode
Goal:
- add a clearer explicit planning workflow in Pi before execution, similar to tools that support structured task planning

Open questions:
- whether this should be implemented through an extension, prompt template, command, or upstream feature
- how much state should be persisted in session vs tracked notes

## Candidate future improvements
- make Pi package installation path username-independent instead of relying on `/home/aj/.pi/agent/npm`
- make MCP servers more Nix-managed for stronger artifact-level reproducibility
- evaluate whether shared MCP services should be used between Pi and OpenCode instead of separate local startup behavior
- trim or reorganize the Zen model list if model selection becomes cluttered

## How to use this file
- add deferred issues that are known but intentionally not fixed yet
- add feature ideas that should survive beyond a single chat session
- move stable architectural decisions into `MEMORY.md`
- keep day-specific implementation details in `memory/YYYY-MM-DD.md`
