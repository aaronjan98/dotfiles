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
- **The user explicitly prefers to be asked rather than guessed at.** If there is any
  hesitancy, ambiguity, or meaningful tradeoff between approaches, stop and ask before
  proceeding. Do not resolve ambiguity silently through assumptions.
- Prefer small, reversible changes over large speculative ones.

## Project behavior
- Each serious project should define its own local context.
- Shared AI config should not be tied to any one project.
- Reusable procedures should become skills.

## Design and architecture preferences

When starting any non-trivial implementation, state the intended architecture **before
writing code** and confirm with the user if there is meaningful ambiguity. Cover:

- **Paradigm:** OOP, functional, procedural, or a mix — and why.
- **Rendering/delivery model:** server-side rendering, client-side rendering, static
  generation, API-only, etc.
- **State management approach:** where state lives and how it flows.
- **Event-driven vs. polling:** prefer event-driven architecture over polling wherever
  it makes sense (file watchers, message queues, webhooks, reactive streams). Only
  use polling when there is no event mechanism available or the overhead isn't justified.

Do not begin scaffolding until the user has agreed on the approach, or the task is
simple enough that there is only one reasonable interpretation.

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
