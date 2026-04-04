# Save Session

## Purpose
Persist the current working session into a structured memory note.

## Behavior
- Save to `memory/YYYY-MM-DD topic.md` where `topic` is a short slug (2–4 words) describing the main thing worked on, e.g. `2026-04-03 lecture-notes-merge skill.md` or `2026-04-03 wronskian review.md`
- If multiple unrelated things were worked on, pick the most significant or the one the user is most likely to search for later
- Before creating a new file, check if any memory file for today already exists whose topic matches what was worked on — if so, append to it rather than creating a duplicate
- If a file for the same date exists but covers a different topic, create a new file
- Use the current time
- Extract:
  - what was worked on
  - key insights
  - decisions
  - open questions
  - next steps

## Rules
- Do not overwrite previous entries
- Do not update MEMORY.md
- Do not update project-memory unless explicitly instructed
