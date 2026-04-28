# Skill: Zettelkasten New Note

## Trigger

Use this skill when creating a new note inside an existing zettelkasten directory —
especially school homework notes, lecture notes, or any note that should link to
surrounding context via directional properties.

---

## Step 1 — Read the directory's Index note first

Before writing anything, read the `Index (<name>).md` file for the directory the note
will live in. This is **not optional** — the Index is the canonical map of what notes
exist and what topics they cover.

**Why this matters:** The Index tells you which existing notes are topically related
to the one you're creating. Without it, you will guess Wrong/East links from filenames
alone, and the guess is frequently wrong (e.g., linking a lab note from the wrong date).

**How to find it:** The directory listing will include a file beginning with `Index`.
For the Math 382 directory it is:
`Index (Math 382 - Scientific Comp & Lab).md`

Read it, then use it to determine which notes belong in `West::` (directly related).

---

## Step 2 — Frontmatter block

Every note begins with this exact block (no blank line before the `#` title):

```
North:: [[Index (Name of Directory).md]] \
Status:: #child \
Tags::

# Note Title
```

- `North::` always links to the Index file of the directory the note lives in.
  See `zettelkasten-new-directory/SKILL.md` for rules on multi-parent `North::` links.
- `Status:: #child` is the default for notes inside a subject directory.
- `Tags::` is left blank unless the user specifies tags.
- The `\` after the North link is a line-continuation for Obsidian's dataview rendering —
  keep it on every property line that is followed by another property line.

---

## Step 3 — School homework note format

Homework notes use a specific **bulleted markdown/LaTeX** style. Follow it exactly.

### Top-matter (inside the note body, after the title)

```markdown
## Chapter / Topic Name

- **Due:** Day. Month DD, YYYY
- **Goal:** One sentence describing the learning objective.
- **Directions:** ...
	- **Chapter X:** X.1, X.2, ...
```

### Problem blocks

Each problem is a top-level bullet, not a heading:

```markdown
- **Problem X.Y.** (pg. NNN) Full problem statement reproduced here, with all LaTeX.
	- Sub-question or context sentence.
	- (a) Sub-part label.
		- Working step.
			- Sub-step or derivation.
		- **Solution.**
	- (b) Next sub-part.
		- **Solution.**
```

**Rules:**
- Problem numbers follow the textbook (e.g., `Problem 6.1`, `Problem 6.6.1`).
- Sub-parts use `(a)`, `(b)`, `(1)`, `(2)` matching the original problem statement.
- Every problem ends with a `**Solution.**` placeholder (or inline solution) at the deepest
  relevant indent level.
- Use `\boxed{ }` around final answers: `$\boxed{ 0.2 }$`
- Inline math: `$...$`. Display math: `$$...$$` on its own line, indented to match context.
- For multi-line display math aligned inside a bullet, use `$$` fenced blocks.
- LaTeX table arrays use `\begin{array}` with `\hline` — not `| --- |` Markdown tables —
  because Obsidian renders LaTeX tables inside `$$` blocks correctly.

### Miscellaneous section

After the problems, add a `## Miscellaneous` section for scratch-work links and
ancillary notes. Leave it empty at creation time; the user fills it in.

```markdown
## Miscellaneous

```

### Footer

```markdown
----

**Related**:

West:: [[Most Relevant Lecture Note]], [[Most Relevant Lab Note]]

# References

[^1]: [Display label](file:///home/aj/Documents/School/...)
```

- `West::` links come from the Index note you read in Step 1 — match by topic and date.
- See `zettelkasten-new-directory/SKILL.md §5` for reference formatting rules
  (URL-encoding, local `file:///` preference, footnote style).

---

## Step 4 — After creating the note

Update the directory's Index file to include a wiki-link to the new note under the
appropriate heading (e.g., `## Homework` or `## Assignments`).

---

## Worked example — Math 382 homework note

```
North:: [[Index (Math 382 - Scientific Comp & Lab).md]] \
Status:: #child \
Tags::

# Homework \# 4

## Gradient Descent

- **Due:** Thu. May 1, 2026
- **Goal:** Apply gradient descent and set up the quadratic regression model.
- **Directions:** Solve from the textbook:
	- **Chapter 6:** 6.1, 6.2, 6.3, 6.6.1

- **Problem 6.1.** Consider a function $f(x, y)$ with gradient $\nabla f(x, y) = (x-1,\ 2y+x)$.
  Starting at $(x=1, y=2)$ with learning rate $\gamma = 1$, execute one step of gradient descent.
	- **Solution.**

## Miscellaneous

----

**Related**:

West:: [[21.4.26 Scientific Computing Lecture Notes]], [[23.4.26 Scientific Computing Lab Notes]]

# References

[^1]: [Homework \#4 problems](file:///home/aj/Documents/School/...)
[^2]: [Math382 Textbook](file:///home/aj/Documents/School/books/...)
```
