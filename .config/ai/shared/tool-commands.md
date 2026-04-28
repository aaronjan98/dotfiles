# Preferred Tool Commands

These are the canonical commands for common file operations.
Always use these instead of improvising alternatives.

## Reading PDFs

```
nix shell nixpkgs#poppler-utils --command pdftotext <path> -
```

Do NOT use the Read tool for PDFs.

## Running Python scripts

This system is NixOS — Python is not in global PATH. Always use `nix shell`
(not the legacy `nix-shell`) since this system uses flakes syntax.

**CRITICAL — do NOT mix `nixpkgs#python3` with package derivations:**

When you include both `nixpkgs#python3` and `nixpkgs#python3Packages.X` in the
same `nix shell` call, the standalone `python3` derivation wins the PATH race and
runs without the packages in its `sys.path`. The packages are fetched to the nix
store but are invisible to the interpreter. This causes `ModuleNotFoundError` even
after a successful download.

**Run a script with no external packages (pure stdlib):**
```
nix run nixpkgs#python3 -- script.py
```

**One-liner with no external packages:**
```
nix run nixpkgs#python3 -- -c "print('hello')"
```

**Run a script with dependencies — specify ONLY the package derivations, NOT python3:**
```
nix shell nixpkgs#python3Packages.pikepdf --command python3 script.py
```

**Multiple packages:**
```
nix shell nixpkgs#python3Packages.numpy nixpkgs#python3Packages.pandas --command python3 script.py
```

If the above still fails (rare — happens when a package derivation does not expose
a usable `python3` binary), fall back to the withPackages expression form:
```
nix shell --impure --expr 'with import <nixpkgs> {}; python3.withPackages(ps: with ps; [numpy pandas])' --command python3 script.py
```

**Common packages:** `python3Packages.pikepdf`, `python3Packages.reportlab`,
`python3Packages.pillow`, `python3Packages.requests`, `python3Packages.numpy`

---

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

### Initializing a new repository

Follow these steps in order when creating a new git-tracked project:

**Step 1 — Initialize:**
```bash
cd /path/to/project/root
g init
```

**Step 2 — Add `.gitignore`, then make the initial commit:**
```bash
g add .gitignore <any other files ready to commit>
g ci -m "initial project scaffold"
```

**Step 3 — Create bare repo on local git server and add remote:**
```bash
sudo -u git git init --bare /srv/git/repos/<repo-name>.git
g remote add local ssh://git@localhost/srv/git/repos/<repo-name>.git
```

**Step 4 — Create bare repo on homelab and add remote:**
```bash
ssh -t aj@sweetpea "sudo -u git git init --bare /srv/git/repos/<repo-name>.git"
g remote add home ssh://git@ssh.aaronjanovitch.com:2222/srv/git/repos/<repo-name>.git
```

**Step 5 — Push to home (sets upstream):**
```bash
g push -u home main
```

After this, `g pushall` will push to all remotes.

> Note: Step 4 requires the homelab (sweetpea) to be reachable. If it is not,
> skip it and inform the user so they can run it manually when available.

---

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

**Standard workflow — commit only** (when user says "commit"):
```
cd /path/to/directory/with/majority/of/changes
dot add .
dot ci -am "imperative present-tense summary of changes"
```

- `cd` into the directory where most of the new or changed files live.
- `dot add .` stages new/untracked files under the current directory.
- `-a` on `dot ci` auto-stages ALL tracked modified files across the entire work tree
  (e.g. `~/.bashrc`, `~/.config/ghostty/config`), so you never need to manually add them.
- Together, `dot add .` + `dot ci -am` captures everything in one commit.

**Commit and push** (only when user explicitly says "commit and push"):
```
cd /path/to/directory/with/majority/of/changes
dot add .
dot ci -am "imperative present-tense summary of changes"
dot pushall
```

**Path gotcha — named relative paths inside `~/.config/`:**
The dotfiles work tree is `$HOME`. If you pass a *named* relative path like
`dot add .config/foo` from inside `~/.config/`, git double-nests it
(e.g. looks for `.config/.config/foo`).
`dot add .` (the literal dot) is always safe — it resolves to the real CWD.
If you must stage a specific file by path rather than using `dot add .`, use its absolute path:
```
dot add /home/aj/.config/some/file
```
Never expand `dot` to the full `git --git-dir=` form — use `dot` for every step.

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
