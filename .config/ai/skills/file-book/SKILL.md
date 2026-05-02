# File Book

## Purpose
Rename and move a downloaded book, paper, or article into `~/Documents/School/books/` following the established naming conventions.

## Use this when
- The user says "move this book to books", "file this download", "add this to the library", or similar
- A new file or folder appears in `~/Downloads/` that is a book, paper, or article

## Naming conventions
Defined in full at `~/Documents/School/CONTEXT.md` under "books/ — naming conventions". Summary:

| Resource type | Pattern |
|---|---|
| Book / textbook / monograph | `Title -- Author(s) -- Year -- Publisher.ext` |
| Journal article / paper / preprint | `Title — Author(s) (Year) — Journal.pdf` |
| Dissertation | `Title -- Author -- PhD Dissertation.pdf` |
| Newspaper / magazine | `Title -- Author -- Publication Name.pdf` |

- Subtitle separator: `;` (not `:`)
- Multiple authors: comma-separated, First Last order
- No colons, no forward slashes, no Anna's Archive artifacts (ISBNs, hashes, source tags)

## Procedure

### Step 1 — Identify the download
Use Python to list `~/Downloads/` (handles Unicode filenames from Anna's Archive):
```
nix run nixpkgs#python3 -- -c "
import os
base = os.path.expanduser('~/Downloads')
for entry in os.listdir(base):
    full = os.path.join(base, entry)
    kind = 'DIR' if os.path.isdir(full) else 'FILE'
    print(f'{kind}: {entry}')
    if os.path.isdir(full):
        for f in os.listdir(full):
            print(f'  {f}')
"
```

Anna's Archive downloads often arrive as a **directory** containing a single PDF with the same name. If that is the case, extract the PDF and delete the wrapper directory at the end.

### Step 2 — Confirm metadata from the file itself
Do not trust the Anna's Archive filename — it truncates authors and may have wrong metadata. Read the title page:
```
nix shell nixpkgs#poppler-utils --command pdftotext -l 1 "/path/to/file.pdf" -
```
Use the title page to confirm: full title, all authors, edition, year, publisher.

### Step 3 — Determine resource type and apply naming pattern
Using the confirmed metadata and the table above, construct the clean filename.

Common corrections needed:
- Anna's Archive truncates author lists — always verify the full author list from the PDF
- Anna's Archive filenames use Unicode RIGHT SINGLE QUOTATION MARK (U+2019) in "Anna's Archive" — shell quoting fails; use Python for all file operations
- Publisher names need canonicalization (see `~/Documents/School/CONTEXT.md`)

### Step 4 — Check for duplicates
Before moving, check whether the title already exists in `~/Documents/School/books/`:
```
ls ~/Documents/School/books/ | grep -i "keyword from title"
```
If a duplicate exists, compare and keep the better copy per the duplicate resolution policy in `~/Documents/School/CONTEXT.md`.

### Step 5 — Move and clean up
Use Python to move the file (handles Unicode filenames safely):
```
nix run nixpkgs#python3 -- -c "
import os, shutil
src = '/path/to/file.pdf'
dst = os.path.expanduser('~/Documents/School/books/Clean Name -- Author -- Year -- Publisher.pdf')
shutil.move(src, dst)
print(f'Moved: {dst}')
# If extracted from a wrapper directory, remove it:
# os.rmdir('/path/to/wrapper/dir')
"
```

## Notes
- Do not use the `Read` tool on PDFs — use `pdftotext` via poppler-utils.
- `python3` is not in PATH on this NixOS system — always use `nix run nixpkgs#python3`.
- If the resource type is ambiguous (book vs. long paper), check the title page for publisher and ISBN — books have ISBNs, papers do not.
