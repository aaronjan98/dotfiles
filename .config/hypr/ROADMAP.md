# ROADMAP.md — Hyprland config

Tracks deferred keybind work, window management features, and workspace behaviour that doesn't belong in the NixOS system config ROADMAP.

---

## Features

### Super+Z: stateful float-zoom toggle
Goal:
- First press: save the window's current size, position, and floating/tiled state → set floating → resize to 1800×980 → center
- Second press: restore exactly — size, position, and whether the window was tiled or floating

Previous attempt (reverted):
- A bash script stored state per window address in `/tmp/hypr-float-zoom/<addr>` using `hyprctl activewindow -j`
- On restore: `settiled` for previously tiled windows; `resizeactive exact` + `movewindowpixel exact X Y,address:ADDR` for previously floating ones
- Did not work reliably — unclear whether the issue was `movewindowpixel exact` syntax, timing between dispatches, or something else
- Reverted to simple `fullscreen, 1` on `Super+Z` (maximizes to work area, tmux-style, no state)

Next investigation:
- Verify `movewindowpixel exact X Y,address:ADDR` dispatch works correctly for restoring float position (test in isolation with `hyprctl dispatch`)
- Consider using `hyprctl dispatch focuswindow address:ADDR` before position/size dispatches to ensure the right window is targeted
- Alternative: store state in a Quickshell service instead of a bash temp file, which could also expose zoom state visually in the bar

### Floating windows: auto-center and default size on Super+V
Goal:
- When toggling a window to floating with `Super+V`, it should land at a sensible size (not whatever the tiled size was) and be centered on screen, without needing manual resize/drag
- Per-app overrides for apps that have a natural preferred float size (e.g. file pickers, image viewers, terminals)

Options:

**Option A — windowrulev2 with `floating:1` filter** (passive, no keybind change):
```
windowrulev2 = center,  floating:1
windowrulev2 = size 60% 70%, floating:1
```
Applies whenever any window enters float state (via `togglefloating`, drag, or spawn rule). Per-app sizes stack on top:
```
windowrulev2 = size 900 600, class:^(org.gnome.Nautilus)$, floating:1
```
Downside: also fires for windows you manually positioned — they'd re-center on every float-toggle cycle.

**Option B — custom dispatch script** (active, replaces `Super+V` binding):
```bash
hyprctl dispatch togglefloating
hyprctl dispatch centerwindow
hyprctl dispatch resizeactive exact 1200 800
```
Bound as `bind = $mainMod, V, exec, float-toggle-center`. Gives precise control and only runs on the explicit keybind — doesn't interfere with windows that spawn floating or are dragged.

Recommended: start with Option A to see if the re-centering on each toggle is annoying; if it is, switch to Option B. Per-app overrides via `windowrulev2` work with both approaches.

Relevant files:
- `~/.config/hypr/conf.d/40-windowrules.conf` — add `center` and `size` rules with `floating:1` filter
- `~/.config/hypr/conf.d/20-binds.conf` — change `Super+V` binding if going with Option B

---

### Floating windows: render above Quickshell bar islands
Status: likely a Wayland layer-shell limitation — needs investigation

Symptom:
- Floating windows that you want to overlap the top bar or left bar render underneath them instead
- `TopBar` and `LeftBar` use `PanelWindow` with no explicit `WlrLayershell.layer`, so they default to `WlrLayer.Top`
- `WlrLayer.Top` surfaces always render above all normal Hyprland windows (tiled and floating) — this is the Wayland protocol's defined stacking order

Why it can't be fixed trivially:
- The layer ordering is: Background → Bottom → Normal windows → **Top** → Overlay
- There is no standard Wayland mechanism to promote a normal window above a `Top`-layer surface
- Lowering the bars to `WlrLayer.Bottom` would put them behind all windows all the time (unacceptable)
- Lowering to `WlrLayer.Normal` puts them at the same level as windows; z-ordering at that level is compositor-controlled and unpredictable

Possible paths to investigate:
1. **Hyprland `layerrule`**: check if newer Hyprland versions support a `layerrule` that adjusts per-surface stacking (e.g. `layerrule = belowwindows, quickshell:topbar`) — not confirmed to exist
2. **Per-popup `WlrLayer.Bottom`**: bars stay at `Top`, but specific popups (brightness, wifi, etc.) are moved to `Bottom` so they appear below floating windows — wrong direction, this makes popups worse
3. **Accept and design around it**: treat the bars as always-on-top chrome (like macOS menu bar) and ensure floating windows are sized/positioned to avoid the bar areas; the auto-center rule above would naturally account for bar height if `margins` are set correctly in `windowrulev2`

Cross-reference: `~/.config/quickshell/ROADMAP.md` for the `WlrLayershell.layer` values in use

### Sticky tiled window (follows workspace switches)

Goal:
- Designate one window as "sticky" so it automatically follows you across horizontal workspace switches (slots within a domain), staying in the same relative screen area and maintaining its size unless the destination workspace is already too full to accommodate it

This is distinct from `pin` (which forces the window into floating mode and overlays all workspaces). The desired behaviour is:
- Window remains tiled
- When you switch to a slot or domain, the window is moved to that workspace silently before or immediately after the switch
- The tiling engine reflows the other windows in the destination workspace to accommodate it
- If the destination workspace already has 3–4 panes, consider whether to reflow or temporarily shrink the sticky window rather than refusing to follow

Why this is non-trivial:
- Hyprland has no native "sticky tiled" concept — `pin` only works for floating windows
- Requires a daemon (or persistent script) subscribed to Hyprland IPC socket `workspace` events
- On each workspace switch event: if a window is flagged sticky, dispatch `movetoworkspacesilent <dest>` to bring it along
- "Same screen area" is hard in a dynamic tiling layout — tiled windows don't have fixed positions; closest approximation is a consistent layout slot (e.g. always rightmost column, always left half) enforced via layout rules or window sizing hints

Open questions:
- How is the sticky window designated? A keybinding that toggles a "sticky-tiled" flag on the focused window (tracked in a state file or Hyprland window tag if the API supports it)
- How to handle the destination workspace being full — reflow (shrink all), or give the sticky window a minimum guaranteed size?
- Whether `hyprctl dispatch movetoworkspacesilent` produces a visible flash or layout jump that needs to be hidden
- Should the sticky window follow domain switches (vertical) as well, or only horizontal slot switches?

Relevant scripts location: `~/.config/hypr/scripts/`

---

## Bugs

### nvim → Hyprland window focus bounces back immediately
Status: undiagnosed

Symptom: when navigating from nvim to an adjacent Hyprland window (via whatever binding triggers `hyprctl dispatch movefocus`), focus briefly lands on the Hyprland window and then snaps back to nvim within the same gesture.

Root cause: unknown — not investigated. Possible causes:
- A nvim autocmd or plugin event fires on `FocusLost` and re-asserts focus (e.g. a smart-splits edge case, a `WinLeave` autocmd calling `wincmd` or similar)
- The binding is wired in both nvim and Hyprland, causing double-dispatch: nvim fires `hyprctl movefocus`, Hyprland moves focus, then Hyprland also sees the raw key and fires a second `movefocus` back
- xremap (present in this config via `modules/xremap.nix`) could be re-intercepting the key after the first dispatch and re-sending it

Relevant files to check when diagnosing:
- nvim smart-splits or navigator plugin config (wherever `hyprctl` is called from nvim)
- `~/.config/hypr/conf.d/20-binds.conf` — check if the same key combo is bound at both layers
- `modules/xremap.nix` — check if xremap is involved in the navigation binding

---

## Known limitations / conceded design decisions

### Unified cross-app navigation with Alt+Shift (f-hold) not fully achievable

Goal (not achieved): use `f` held (`Alt+Shift`, per `kanata-internal.kbd` `fj_chord`) + h/j/k/l to navigate seamlessly across nvim splits, tmux panes, and Hyprland windows — one motion chord that works everywhere.

What worked:
- nvim → Hyprland window: nvim smart-splits (or equivalent) detects when the cursor is at a pane edge and calls `hyprctl dispatch movefocus` directly, handing off to the compositor

What didn't work:
- Hyprland window → nvim: Hyprland intercepts `Alt+Shift+<key>` globally before any application sees it, executes its own `movefocus`, and nvim never receives the keypress to route internally

Root cause: Hyprland keybindings are compositor-global and fire before the focused application's input loop. There is no per-window "pass through if the app is nvim/tmux" mechanism in the standard keybind system.

Conceded solution: `Super+arrow keys` for Hyprland window focus within a workspace (bound to `movefocus`; distinct from `Super+h/j/k/l` which is workspace/domain switching). nvim and tmux keep their own internal navigation bindings. The two layers do not unify.

If revisited: the only viable path is a script that replaces the Hyprland `movefocus` binding — it checks the focused window class (is it a terminal running nvim/tmux?), and if so, sends the keystroke to the application via `wtype` or `ydotool` instead of calling `movefocus`. This is fragile (requires detecting nvim/tmux state from the outside) and was not worth the complexity at time of writing.

---

## Features

### Custom cursor: thin black border instead of filled dark base

Current state:
- Theme: `breeze-hacked-cursor-theme` (clayrisser), built in `pkgs/breeze-hacked-cursor/default.nix`
- Built with `--accent-color "#E62600"` (red) and `--base-color "#192629"` (near-black, currently made partially transparent manually)
- The base-color fills the main cursor body — this is the "black/transparent" part you want gone
- Goal: remove the filled dark base entirely and replace with a thin black stroke around the red shape only

Implementation options:
1. **Patch the SVG sources at build time**: in `preBuild` in the Nix derivation, after `recolor-cursor.sh` runs, use `sed` or a Python script to replace the filled base shapes with a stroked outline — avoids forking the upstream repo
2. **Pass transparent base-color**: try `--base-color "transparent"` or `--base-color "#00000000"` to the recolor script — may or may not be supported depending on how the script handles alpha; simplest to try first
3. **Layer approach** (user's instinct is correct): render a slightly larger all-black version of the cursor shape as the bottom layer, then the red shape on top — this is exactly how most cursor themes produce outlines, but the result is a thick outline proportional to the size difference, not a thin stroke

The thin-border look requires the stroke approach (option 1 or 2). The stacking approach (option 3) produces a thicker outline and is harder to control precisely.

Relevant file: `pkgs/breeze-hacked-cursor/default.nix`

### Cursor size: load from system, not Hyprland config

Current state:
- `XCURSOR_SIZE=30` and `HYPRCURSOR_SIZE=30` are set via Hyprland `env =` directives in `~/.config/hypr/conf.d/00-env.conf`
- These are not available until Hyprland reads its own config, causing the cursor to render at the default system size briefly at startup before snapping to 30

Fix:
- Move `XCURSOR_SIZE`, `XCURSOR_THEME`, `HYPRCURSOR_SIZE`, `HYPRCURSOR_THEME` into `environment.sessionVariables` in `hosts/thinkpad-t14/configuration.nix` — NixOS writes these to `/etc/environment` which is available to the session before Hyprland initialises
- Remove the duplicate `env =` lines from `00-env.conf` once the system vars are set (or keep them as a fallback — harmless if identical)

Relevant files:
- `~/.config/hypr/conf.d/00-env.conf` — current location (remove after migration)
- `hosts/thinkpad-t14/configuration.nix` — add to `environment.sessionVariables`

---

## How to use this file

- Add Hyprland-specific keybind, workspace, and window management deferred work here
- Cross-reference `~/nixos-config/docs/ROADMAP.md` for system-level Hyprland module changes
- Cross-reference `~/.config/quickshell/ROADMAP.md` for shell-layer features that interact with Hyprland IPC
