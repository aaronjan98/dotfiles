# Preferred Tool Commands

These are the canonical commands for common file operations.
Always use these instead of improvising alternatives.

## Reading PDFs

```
nix shell nixpkgs#poppler-utils --command pdftotext <path> -
```

Do NOT use the Read tool for PDFs.

## Converting DOCX to PDF

```
libreoffice --headless --convert-to pdf '/path/to/file.docx' --outdir '/path/to/output/'
```
