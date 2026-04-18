---
description: Primary build agent with full tool access for development work
mode: primary
---

# OpenCode Bootstrap

## System architecture
This machine uses a structured, agent-agnostic AI workspace.
Full rules are at: ~/.config/ai/shared/agent-orientation.md

---

## On session start — always do this

1. Read: ~/.config/ai/shared/agent-orientation.md
2. Read: ~/.config/ai/shared/tool-commands.md

3. Check the current working directory for these files and read any that exist:
   - CONTEXT.md
   - MEMORY.md
   - DEPENDENCIES.md

4. If no CONTEXT.md exists here, check ~/Repositories/ROUTER.md to orient.

5. Do not load unrelated repositories or search broadly without routing.

---

## Memory storage — always follow this

Store session notes in:       memory/YYYY-MM-DD.md    (append, never overwrite)
Store durable knowledge in:   MEMORY.md               (promote only when appropriate)

---

## Skills
Reusable procedures live at: ~/.config/ai/skills/
Use a skill when the task matches it rather than improvising.
Notable: save-session, zettelkasten-search, academic-book-extraction, jupyter-notebook-inspection