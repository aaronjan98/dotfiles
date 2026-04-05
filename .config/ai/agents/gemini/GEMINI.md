# Gemini Bootstrap

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

This system uses file-based memory shared across all agents. Do NOT use save_memory
for session notes, project facts, or user preferences — that store is Gemini-only
and invisible to other agents.

Store session notes in:       memory/YYYY-MM-DD topic.md  (new file per topic, append if same topic)
Store durable knowledge in:   MEMORY.md                   (promote only when appropriate)

Use save_memory ONLY for Gemini-specific behavioral preferences (e.g. output formatting)
that have no equivalent in the shared file system and would never be needed by another agent.
Use the save-session skill (~/.config/ai/skills/save-session/) at end of session.

---

## Skills
Reusable procedures live at: ~/.config/ai/skills/
Use a skill when the task matches it rather than improvising.
Notable: save-session, zettelkasten-search, academic-book-extraction, jupyter-notebook-inspection
