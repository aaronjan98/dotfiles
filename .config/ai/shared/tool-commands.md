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

## Git operations

Commit messages must always be imperative and present-tense (e.g. "add SVD notes", "update memory with competency gaps", "fix typo in CONTEXT.md"). Do NOT use past tense.

### Which directories are tracked by which system

| Location | Tracked by | Command |
|---|---|---|
| `~/nixos-config/` | regular git repo | `g` |
| `~/Repositories/` (CONTEXT.md, memory/, etc.) | NOT git — mirrored by systemd timer | n/a |
| `~/.bashrc`, `~/.bash_aliases`, `~/.bash_profile` | dotfiles bare repo (`~/.dotfiles`) | `dot` |
| `~/.config/` | dotfiles bare repo (`~/.dotfiles`) | `dot` |
| `~/.gitconfig`, `~/.dotfiles.gitignore` | dotfiles bare repo (`~/.dotfiles`) | `dot` |

**For existing files** — confirm with:
```
git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" ls-files <path>
```
Returns the path if tracked, empty if not.

**For new files** — `ls-files` won't help since the file isn't tracked yet. Use the top-level directory list above to determine whether `dot` applies.

### Regular repos (use `g`)

Use the `g` alias for all standard git operations.

**Commit only** (when user says "commit"):
```
g add .
g ci -m "imperative present-tense summary of changes"
```

**Commit and push** (only when user explicitly says "commit and push"):
```
g add .
g ci -m "imperative present-tense summary of changes"
g pushall
```

### Dotfiles repo (use `dot`)

`~/.config/ai/` and other home directory config files are tracked via a bare repo at `~/.dotfiles`.
Use the `dot` command (never plain `git`, never `g`).

**Commit only** (when user says "commit"):
```
dot add .
dot ci -m "imperative present-tense summary of changes"
```

**Commit and push** (only when user explicitly says "commit and push"):
```
dot add .
dot ci -m "imperative present-tense summary of changes"
dot pushall
```

## Installing local AI models (llmfit + llama.cpp)

Models are downloaded and served via llmfit and llama.cpp. All llama tools (llama-server, llama-bench, llama-cli) are already installed via the `llama-cpp` nixpkgs package.

Downloaded models are stored at: `~/.cache/llmfit/models/`

**Step 1 — Find a GGUF repo:**
```
llmfit hf-search <model-name>-GGUF
```
Use `hf-search`, not `search`. Prefer official author repos over community quantizers.
Use bartowski only if you need IQ-series quants the author doesn't publish.

**Step 2 — List available quants:**
```
llmfit download <repo> --list
```

**Step 3 — Download (default to Q4_K_M):**
```
llmfit download <repo> --quant Q4_K_M
```

**Step 4 — Benchmark before serving:**
```
llama-bench -m ~/.cache/llmfit/models/<model>.gguf -n 128 -p 512 -t 8
```
Use 8 threads. This hardware (Ryzen 7 PRO 5850U, integrated Vega) is CPU-only and memory-bandwidth-bound — more threads degrade performance.

**Step 5 — Serve:**
```
llama-server \
  -m ~/.cache/llmfit/models/<model>.gguf \
  -c 4096 \
  -t 8 \
  --host 127.0.0.1 \
  --port 8080
```

Connect Open WebUI via Settings → Connections → OpenAI-compatible: `http://127.0.0.1:8080/v1`
