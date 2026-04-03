# MEMORY.md

## Read on every session
- `CONTEXT.md` — project overview, rules, file paths, working instructions
- `project-memory/[active-goal].md` — current goal state (update this line when goal changes)

## Read when relevant
- `memory/YYYY-MM-DD.md` — session logs (read when reviewing prior work or resuming a task)
- `spec/[filename].md` — requirements or specs (read when working on something spec-driven)

## Reference only (not agent-specific, but agents may read when needed)
- `notes/` — research notes, source lists, reference material

## Not for agents
- [list any output dirs, submitted files, or human-only drafts here]

---

## Durable notes
[Write stable facts, decisions, and preferences directly here when they don't warrant
their own project-memory file. For larger or ongoing goals, use project-memory/ instead.]

---

## Session log index
- [YYYY-MM-DD](memory/YYYY-MM-DD.md) — [one-line description of what was worked on]

---

## Rules
- Do not leave important decisions only in chat — write them to project-memory/ or spec/.
- Do not put transient session notes into project-memory/ — those go in memory/YYYY-MM-DD.md.
- When a goal completes, remove it from "Read on every session" — it becomes reference only.
- Keep this file as a loading manifest, not a dump of project facts.
