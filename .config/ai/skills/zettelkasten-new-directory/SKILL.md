# Skill: Zettelkasten New Directory

## Trigger
Use this skill when creating a new folder/directory anywhere inside the zettelkasten vault
(`~/Repositories/self-hosted/zettelkasten/`), or when placing a new note inside an existing
directory.

---

## Before creating any note — find optimal placement by traversal

Do not guess placement from the note's topic alone. Traverse the vault's existing structure:

1. **Start at the top-level index** — read `Index (Spaces).md` (the vault root MOC) to identify
   which top-level section fits the note (`Inside/`, `Zettels/`, `Outside/`, etc.)

2. **Traverse down via CONTEXT.md and Index files** — read the CONTEXT.md or Index file of
   each candidate subdirectory to determine which one the note belongs in. Continue until you
   reach the most specific subdirectory that fits.

3. **Place the note in that subdirectory.** The `North::` frontmatter is then:
   - **First link:** the Index file of the directory the note was placed in
   - **Subsequent links:** any parent or cross-domain Index files relevant to the topic,
     found by searching the vault (`find ~/Repositories/self-hosted/zettelkasten -name "Index (X)*"`)

   Example: a git gotcha placed in `Inside/Projects/` gets:
   `North:: [[Index (Projects).md]], [[Index (Git).md]]`
   — where `Index (Projects).md` is the directory's own index, and `Index (Git).md` was
   found by searching the vault.

4. **Never assume an Index file doesn't exist** — always search the full vault before
   concluding one needs to be created.

---

## Steps

### 1. Read the templates first

Before creating any files, read:
- `~/Repositories/self-hosted/zettelkasten/Documents/Templates/Map of Content.md` — used for Index files
- `~/Repositories/self-hosted/zettelkasten/Documents/Templates/Note Template.md` — used for regular notes

These are the canonical formats. Follow them exactly. The templates use Templater scripts
(`tp.user.*`) that run dynamically in Obsidian — agents hardcode the equivalent values instead.

### 2. Create an Index file for every new directory

Every directory in the zettelkasten must have an `Index (<name>).md` file inside it.

- Filename must start with `Index`
- The name in parentheses should be descriptive of the content — does not need to match the
  folder name exactly
- Use the **Map of Content** template
- `North::` should point to the Index file of the **parent** directory
- List all notes in the directory as wiki-links, organized under descriptive headings
- Update this file whenever a new note is added to the directory

### 3. Format all regular notes with the Note Template

Every non-index, non-agent note must follow the **Note Template**.

- `North::` points to the Index file of the directory the note lives in
- `Status::` and `Tags::` lines are always present
- `# References` section is always present at the bottom

### 4. Know the purpose of each directory type

Every zettelkasten project directory follows this structure. Understand what each layer is *for*,
not just its format.

| Directory / File | Role | Who reads it |
|-----------------|------|--------------|
| `Index (<name>).md` | Map of Content — navigational overview for the human; orients you at each directory level | Human (Obsidian) |
| `CONTEXT.md` | Static project description for agents: what the project is, directory architecture, working rules, current workflow stage. Answers: *"What is this project?"* | Agent (on load) |
| `MEMORY.md` | Agent loading manifest — lists exactly what to read each session. Also holds stable durable facts. Answers: *"What must I load right now?"* | Agent (on load) |
| `project-memory/*.md` | Living documents tracking the **current evolving state** of the work: decisions made, active goals, checklists, deliverables-in-progress. Updated frequently. Answers: *"Where are we right now?"* Distinct from CONTEXT.md, which describes the project — project-memory describes the project's current state. | Agent (on load, per MEMORY.md) + Human |
| `notes/` | All working content: source reviews, research notes, math workthroughs, drafts. Can have subdirectories (each needs its own Index). Reference material that persists long-term lives here alongside more ephemeral workspace notes. | Human primarily |
| `memory/YYYY-MM-DD.md` | Ephemeral session logs. Written at end of session. Read only when resuming prior work. | Agent (when resuming) |

**Format rules:**
- `CONTEXT.md`, `MEMORY.md`, `memory/` logs — exempt from zettelkasten templates; keep their own format
- `project-memory/` notes — **do** use the Note Template; directory **does** need an Index
- `notes/` and all subdirectories — use Note Template for notes, Index file for each directory
- `memory/` — no Index file needed

AI agent files should still be linked from the directory's Index under an **AI Agent Files**
heading so they are discoverable from Obsidian.

### 5. Reference formatting

The `# References` section at the bottom of every note uses footnote-style citations.

**Inline usage:** place `[^key]` at the point in the text where the source is cited.

**Entry format — local file (preferred):**
```
[^key]: [Display Title — Author (Year)](file:///home/aj/Documents/School/books/Encoded%20Filename.pdf)
```

**Entry format — external link (fallback when no local file):**
```
[^key]: [Display Title — Author (Year)](https://doi.org/...)
```

**Prefer local file links** over external URLs whenever the resource exists locally.
Local resources live in `~/Documents/School/books/`.

**All local `file:///` paths must be URL-encoded** — Obsidian requires this to open PDFs:
- Space → `%20`
- Em dash (—) → `%E2%80%94`
- Any non-ASCII character → UTF-8 percent-encoded bytes (e.g. ó → `%C3%B3`)

**Filename convention** for files in `~/Documents/School/books/`:
```
Title — Author(s) (Year) — Journal or Publisher.pdf
```

**For projects with many resources**, create a `paper-acquisition.md` in `project-memory/`
as the single authoritative list of all resources with acquisition status and local links.
Individual note footnotes reference the same files, but `paper-acquisition.md` is the
canonical source of truth. Use checkboxes (`- [ ]` / `- [x]`) to track acquisition status.

---

### 6. Directional link semantics

| Property | Meaning |
|----------|---------|
| `North::` | Parent/overarching concept |
| `South::` | Child — ideas that stem from this note |
| `West::` | Directly related or closely relevant |
| `East::` | Tangentially related or opposing viewpoint |

---

### 7. Example structure

```
My Project/
├── Index (My Project).md          ← Map of Content, North→ parent Index
├── CONTEXT.md                     ← AI agent file, exempt
├── MEMORY.md                      ← AI agent file, exempt
├── notes/
│   ├── Index (my proj notes).md   ← Map of Content, North→ Index (My Project)
│   └── Some Reference.md          ← Note Template, North→ Index (my proj notes)
├── project-memory/
│   ├── Index (my proj goals).md   ← Map of Content, North→ Index (My Project)
│   └── goal-name.md               ← Note Template, North→ Index (my proj goals)
└── memory/
    └── 2026-04-04.md              ← AI session log, exempt, no Index needed
```
