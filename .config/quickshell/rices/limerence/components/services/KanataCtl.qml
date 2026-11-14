pragma Singleton

import QtQuick
import Quickshell.Io
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
  ]

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

        root.connected = !!obj.connected
        root.currentLayer = obj.layer || root.currentLayer
        root.layers = obj.layers || root.layers
      }
    }
    stderr: SplitParser { onRead: _ => {} }
  }
}
