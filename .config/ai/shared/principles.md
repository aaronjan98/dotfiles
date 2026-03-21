# AI Workspace Principles

This directory contains the canonical shared rules for AJ's agentic workspace.

## Core principles
- Route before loading context.
- Keep bootstrap files small.
- Prefer project-local context over broad search.
- Use external knowledge only when a project declares it relevant.
- Separate operational notes from durable project knowledge.
- Be explicit about uncertainty.

## Communication rules
- Write in plain, clear language.
- Do not pretend to know something you have not verified.
- Ask clarifying questions when the task is underspecified.
- Prefer small, reversible changes over large speculative ones.

## Project behavior
- Each serious project should define its own local context.
- Shared AI config should not be tied to any one project.
- Reusable procedures should become skills.

## Execution safety rules
- Prefer deterministic scripts over direct bulk filesystem mutation.
- For rename, move, or delete operations affecting many files, first generate a script with a dry-run mode.
- Show the proposed operations before executing destructive or large-scale changes.
- Use direct file editing mainly for small, reviewable changes.

## Shared skills
Shared skills live in:

- `~/.config/ai/skills/`

These are reusable procedures, not automatically loaded context.

Use a skill when the task matches it rather than improvising a new workflow.

Current notable shared skills include:
- `save-session`
- `zettelkasten-search`
- `academic-book-extraction`
- `jupyter-notebook-inspection`

Project-specific files may reference which skills are most relevant.

## Session persistence rule
Conversations do not persist; artifacts do.

When a session produces useful work, the preferred pattern is:
- save operational residue into `memory/YYYY-MM-DD.md`
- promote durable conclusions only when explicitly appropriate
- do not treat chat history as project memory

## Save-session rule
Use the `save-session` skill as the default way to persist a working session.

By default, `save-session` should:
- append to `memory/YYYY-MM-DD.md`
- summarize what was worked on
- record key insights
- record decisions
- record open questions
- record next steps

It should not:
- overwrite earlier notes
- update `MEMORY.md`
- update `project-memory/` unless explicitly instructed

## Bulk filesystem safety rule
For rename, move, delete, or large repetitive changes:
- prefer script generation over direct agent mutation
- include a dry-run mode
- review expected changes before execution
