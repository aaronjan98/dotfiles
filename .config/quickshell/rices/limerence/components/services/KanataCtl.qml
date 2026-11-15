pragma Singleton

import QtQuick
import Quickshell.Io
import Quickshell
import "../../config" as C

// Backend for the left-bar Kanata mode island (KanataIsland.qml). Kanata's TCP
// server is plain TCP (port 7979, set via services.kanata.keyboards.internal.port
// in nixos-config modules/kanata.nix) and Quickshell's Socket/SocketServer only
// speak unix domain sockets (QLocalSocket under the hood) -- so a helper process
// (nixos-config/scripts/kanata-ctl-daemon.py) bridges TCP to stdio JSON, the same
// shape as ObsCtl.qml's daemon. See quickshell project-memory/kanata-island.md.
Item {
  id: root
  visible: false

  readonly property string daemonScript: "/home/aj/nixos-config/scripts/kanata-ctl-daemon.py"

  property bool connected: false
  // NOTE: named currentLayer, not "layer" -- QtQuick Item has a built-in grouped
  // property called `layer` (GPU layer effects) that is FINAL; redeclaring it as a
  // plain string errors with "Cannot override FINAL property" at load time.
  property string currentLayer: "default"
  property var layers: []

  // Modes shown in the island, top to bottom. `arrows` and `nums` are
  // layer-while-held (momentary) in kanata-internal.kbd and are deliberately
  // excluded -- they'd flicker during normal typing and are meaningless as
  // click targets. An entry whose key isn't in `layers` still renders (dimmed,
  // unclickable in the widget) so a missing layer reads as a config problem,
  // not a vanished mode.
  readonly property var modes: [
    { key: "default",   word: "Norm", colour: C.Appearance.modeColDefault },
    { key: "capslayer", word: "Cap",  colour: C.Appearance.modeColCaps },
    { key: "majlayer",  word: "Maj",  colour: C.Appearance.modeColMaj },
    // execlayer is one-shot (tap left Super to enter, any key runs its
    // action and bounces straight back to default, see kanata-internal.kbd)
    // -- it'll still render dimmed/unclickable here until the host actually
    // has the layer (nixos-rebuild switch + kanata-internal restart).
    { key: "execlayer", word: "Exec", colour: C.Appearance.modeColExec },
  ]

  // ---- exec mode (Phase 3: push-msg-triggered app/URL launches) ----
  // execlayer's keys (kanata-internal.kbd) each push-msg a short semantic
  // string (e.g. "youtube") and bounce back to default in the same tap --
  // see that file's own comments for the full key map. This table is the
  // ONE place that maps those strings to actual commands, kept out of the
  // .kbd (and out of this file as a literal) so new exec actions are a JSON
  // edit, not a kanata config rebuild -- same split as accents.json/AccentCtl.
  readonly property string execTableFile: Quickshell.env("HOME") + "/.config/quickshell/exec.json"
  property var execActions: ({})

  function runExec(name) {
    var argv = execActions[name]
    if (!argv || !Array.isArray(argv) || argv.length === 0) return
    Quickshell.execDetached(argv)
  }

  function send(obj) { proc.write(JSON.stringify(obj) + "\n") }
  function setLayer(name) { send({ cmd: "set_layer", layer: name }) }
  function refresh() { send({ cmd: "refresh" }) }

  Process {
    id: proc
    command: [root.daemonScript]
    stdinEnabled: true
    running: true

    stdout: SplitParser {
      onRead: data => {
        const line = (data || "").trim()
        if (!line) return
        let obj
        try { obj = JSON.parse(line) } catch (e) { return }
        if (obj.transientError !== undefined) return
        // A MessagePush relay, not a state snapshot -- obj has no
        // connected/layer/layers fields, so it must be handled (and
        // returned from) before the assignments below, or they'd
        // incorrectly stomp connected/currentLayer/layers with undefined.
        if (obj.execMsg !== undefined) { root.runExec(obj.execMsg); return }

        root.connected = !!obj.connected
        root.currentLayer = obj.layer || root.currentLayer
        root.layers = obj.layers || root.layers
      }
    }
    stderr: SplitParser { onRead: _ => {} }
  }

  FileView {
    id: _execTableFile
    path: root.execTableFile
    // Without this, editing exec.json has no effect until the next full
    // quickshell restart -- defeats the entire point of keeping the
    // key->command table out of the .kbd (see the comment on execActions).
    watchChanges: true
    onLoaded: {
      try {
        var o = JSON.parse(text())
        if (o && o.actions) root.execActions = o.actions
      } catch (e) { /* keep last-good table on a partial write */ }
    }
    // Missing exec.json just means execlayer's keys silently no-op --
    // not a reason to block the rest of KanataCtl from working.
    onLoadFailed: {}
  }
}
