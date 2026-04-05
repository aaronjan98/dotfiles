# Lecture Notes Merge

## Purpose
Extract content from a lecture slide PDF and merge it with the student's class notes into a single, clean Obsidian-ready markdown file.

## Use this when
- The user provides a PDF of lecture slides (possibly with handwritten annotations) and a corresponding class notes `.md` file
- The user asks to "merge", "integrate", or "combine" their notes with a PDF
- The user asks to extract slides and incorporate them into their notes

## Inputs
- path to the class notes `.md` file
- which pages to process (or "all remaining")
- which line number the already-merged content ends at (so you don't touch what's done)
- path to the slide PDF — **optional if the notes file already has a References section**: check the bottom of the notes file first for `file://` links; the PDF path is often already there and does not need to be provided by the user explicitly. If multiple PDFs are referenced, ask the user which one applies to the section being merged.

---

## Step 1 — Extract the PDF

Use two methods in combination:

### Text layer (printed text)
```bash
nix-shell -p python3Packages.pypdf --run "python3 -c \"
import pypdf
reader = pypdf.PdfReader('/path/to/slides.pdf')
print(f'Total pages: {len(reader.pages)}')
for i in range(START, END):
    print(f'=== PAGE {i+1} ===')
    print(reader.pages[i].extract_text())
\""
```
- Symbol corruption is expected: `↑` = `∞`, `→` = `−`, `↓↑` = `→∞`. Reconstruct from context.
- Garbled handwriting in the text layer is normal — use the image method below for that.

### Page images (handwritten annotations)
```bash
nix-shell -p poppler-utils --run "pdftoppm -r 200 -png -f PAGE_START -l PAGE_END '/path/to/slides.pdf' /tmp/slides_page"
```
Then read each image with the Read tool. The model can interpret handwriting directly from the rendered PNG.

Always render pages as images when they contain handwriting, even if the text layer extracted something — the text layer garbles handwriting.

---

## Step 2 — Read the class notes file

Read the `.md` file in full. Note:
- The line number where already-merged content ends (user will specify, or identify from context)
- The density and style of student notes under each section/slide marker

---

## Step 3 — Detect note style and propose a merge strategy (REQUIRED before any edits)

Before making any changes, read the notes and describe what you observe, then propose a specific strategy and **wait for the user to confirm or adjust** before proceeding.

### The three note styles

**Extraction-only (blank template)** — the notes file is empty or contains only frontmatter/headers with no content. The PDF is the sole source.
- Approach: convert the entire PDF into clean bulleted notes as if writing them from scratch. The output should stand alone as valid, complete notes. Do not add scaffolding, placeholder bullets, or prompts for the student to fill in — just the content. The student will annotate during or after class.
- Skip the confirmation step and proceed directly — there is nothing to preserve and no ambiguity about what to do.

**Sparse style** — the student wrote little; sections are mostly empty, have `**N.B.**` placeholders, or trail off with `...`/`?`. The PDF content is the primary source; student annotations are supplementary.
- Approach: fill in the slide content as the main body; weave student comments in as sub-bullets or "Professor comment:" lines

**Dense style** — the student copied extensively from the board; sections already have complete mathematical derivations and professor remarks. The student's notes are authoritative.
- Approach: insert formal slide content (definitions, notation, Python code, titles) as sub-bullets *above* the student's existing notes for each slide marker; never overwrite what's there

**Mixed** — different sections have different densities. This is common and valid.
- Approach: handle each section according to its own density

### What to say to the user (sparse, dense, and mixed only)

State something like:

> I've read the notes and the PDF. Here's what I see:
> - Slides 2–4: student has dense professor-copied notes → I'll insert formal notation above, leave notes untouched
> - Slides 5–6: mostly empty markers with N.B. placeholders → I'll fill these in from the slides
> - Slide 7: has a partial formula and a `?` → I'll complete it
>
> Does this approach work, or would you like me to treat any section differently?

Wait for the user's response before making any edits. If they want a different level of intervention for any section, adjust accordingly.

---

## Step 4 — Formatting rules (strictly enforced)

- Every sub-bullet is indented with **one tab** more than its parent (the file uses tabs, not spaces)
- **No blank lines between sub-bullet points** — blank lines only between top-level bullet points
- No horizontal rules (`---`) to separate sections; use blank lines only
- Numbered items inside a bullet list use `1.`, `2.`, `3.` syntax at the appropriate indent level
- Display math goes on its own line inside the bullet: `- text $$...$$` or on a new line with extra indent
- Use `$\displaystyle` for inline sums/limits that need full size

### Style examples

**Sparse style output:**
```markdown
3. (pg. 2) **Ratio Test**
	- If $a_n \neq 0$ and $\lim_{n\to\infty}|a_{n+1}/a_n| = L$, the series **converges absolutely** if $|x-x_0|L < 1$ and **diverges** if $|x-x_0|L > 1$.
	- Professor comment: allows us to evaluate the ratio of two consecutive terms
```

**Dense style output** (formal content inserted above student notes):
```markdown
- (slide 7) Regression Coefficients Using Centering
	- let $\bar{x} = \frac{1}{n}\sum x_i$, $\bar{y} = \frac{1}{n}\sum y_i$; centered variables $X_i = x_i - \bar{x}$, $Y_i = y_i - \bar{y}$
		- $a = \langle X,Y\rangle / \langle X,X\rangle$, $b = \bar{y} - a\bar{x}$
	- Python: `(a, b) = np.polyfit(x, y, 1)`
	- [student's existing notes follow unchanged below this line]
```

---

## Step 5 — Merge rules

### Explicit student markers — always fill these in regardless of style
| Marker | Meaning |
|--------|---------|
| `**N.B.**: fill in` | Replace with content from slides |
| `**N.B.**: fill in before and X` | Fill in the surrounding preamble AND the missing section X |
| `...` at end of a line | Line is incomplete — fill in from slides |
| `..` at end of a line | Same as above |
| `?` at end of a line | Student was unsure — use best educated guess from slide context; remove the `?` |
| `**N.B.**: fix typos` | Fix all typos in that block |

### Implicit fixes (regardless of style)
- Clearly wrong LaTeX (e.g., `^n` where `^2` is correct, `ba_3` where `6a_3` is correct) — fix silently
- Obvious spelling errors — fix silently
- Truncated sentences (sentence ends mid-thought with no punctuation) — complete from slide context
- Typos in slide marker labels (e.g., `(side 6)` → `(slide 6)`) — fix silently

### Dense style — what to add above the student's notes for each slide
- Slide title if the marker is bare: `(slide 4)` → `(slide 4) Simple Linear Regression`
- Formal definitions and model equations not already present
- Python code if mentioned but not written out
- A `(slide N)` label if a slide's content is in the notes without any marker
- Slide numbers in student notes may not match PDF page numbers — match by topic, not by number
- If a slide has no corresponding PDF page (board-only content), leave it entirely alone

### Dense style — what NOT to do
- Do not rewrite, reorder, or remove any of the student's existing notes
- Do not add your own commentary or synthesis
- Do not duplicate content already in the student's notes

### Sparse style — what to include
- All formal definitions, theorem statements, and formulas from printed slide boxes
- Summary/closing pages — always include even if the student made no notes on them
- Preamble paragraphs that introduce multiple sections
- Problem statements for examples the student left as bare headers
- Student comments woven in as "Professor comment:" sub-bullets or placed in context

### All styles — what NOT to invent
- Do not invent content not present in the slides or student's notes

---

## Step 6 — Output

Edit the notes file directly using the Edit tool. Do not rewrite the entire file — make targeted replacements for each changed section, one edit per logical section.

Only edit lines **after** the line number the user specifies as the merge boundary.

After all edits, check the References section at the bottom of the notes file:
- Notes files end with a `# References` section containing footnote-style `file://` links to source PDFs
- If the PDF just merged is **not already listed**, add it as the next footnote: `[^N]: [Slide title](file:///path/to/slides.pdf)`
- If it is already listed, leave the References section untouched

Then do a final Read of the modified section to verify the result looks correct before finishing.

---

## Technical notes

- `pypdf` is available via `nix-shell -p python3Packages.pypdf`
- `pdftoppm` is available via `nix-shell -p poppler-utils` (not `poppler` or `poppler_utils` — those don't work)
- Render at `-r 200` resolution; sufficient for handwriting legibility
- The student's file uses **tabs** for indentation throughout — always match this, never use spaces
- The student sometimes uses `i` as the summation index instead of `n` — don't correct it inside blocks you're otherwise leaving untouched
