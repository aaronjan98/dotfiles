# 2026-11-15 — exec.json: added torrent action, q/k remap

## What was worked on

Continuation of [[2026-11-14 kanata-exec-mode-phase3]]. Added a `"torrent"`
entry to `exec.json` (`["firefox", "http://torrent.home"]`) to go with the
kanata-side remap (`q` now pushes "torrent" instead of "kitty"; `k` now pushes
"kitty", previously unmapped) — see the nixos-config-side memory note of the
same name for the full `.kbd` diff and host details.

## Key insight

User reported `q` "wasn't working," including before this session's edit (when
`q` was still bound to kitty). Spent most of the session chasing this down.
Full debugging story (Hyprland native-bind red herring, a misleading `nc` TCP
tap, and the journalctl `--debug` approach that actually worked) is written up
in `~/nixos-config/memory/2026-11-15 kanata-exec-q-k-remap.md` — not duplicated
here since it's really one story split across two repos.

Short version: kanata, the daemon relay, and `KanataCtl.qml`'s `runExec()` were
all firing correctly the whole time (confirmed via a temporary debug trace in
`runExec()`, same technique as the earlier Obsidian bug — added and removed,
no net diff left in `KanataCtl.qml`). The actual outcome was a **background**
Firefox tab (easy to miss, doesn't steal focus) showing **404 Not Found** for
`http://torrent.home` — a service-config problem (wrong path for whatever's
reverse-proxied there), not a kanata-island bug.

## Open questions / next steps

- `docs/kanata-island.md`'s key-map table is now stale: still lists `q`→kitty
  and has no `k` entry. Not updated this session (wasn't asked) — fix next time
  docs are touched.
- Still need the correct sub-path/port for the torrent client behind
  `torrent.home` to actually fix the `exec.json` URL.
- `MEMORY.md` and `project-memory/kanata-island.md` intentionally NOT updated
  this session per the save-session skill's rules (only update those when
  explicitly asked).
