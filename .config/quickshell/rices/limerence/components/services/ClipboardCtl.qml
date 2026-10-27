pragma Singleton

import QtQuick
import Quickshell.Io

// Shared clipboard-history state, so both the bar icon (ClipboardIcon/
// ClipboardPopup, per-monitor) and the Super+Ctrl+V Hyprland keybind
// (via `qs ipc call clipboard toggle`) drive the same popup. Mirrors the
// Notifs singleton's IpcHandler-in-a-singleton pattern.
Item {
  id: root
  visible: false

  property bool open: false
  property var entries: []   // each: raw "id\tpreview" line from `cliphist list`
  property int selectedIndex: 0   // keyboard-navigated row; hover also moves this

  function entryId(line) {
    const i = line.indexOf("\t")
    return i < 0 ? line : line.slice(0, i)
  }

  function entryPreview(line) {
    const i = line.indexOf("\t")
    return i < 0 ? line : line.slice(i + 1)
  }

  function refresh() {
    listProc.running = false
    listProc.running = true
  }

  function show() {
    root.open = true
    root.selectedIndex = 0
    root.refresh()
  }

  function hide() { root.open = false }
  function toggle() { root.open ? root.hide() : root.show() }

  function moveSelection(delta) {
    if (root.entries.length === 0) return
    let i = root.selectedIndex + delta
    if (i < 0) i = 0
    if (i > root.entries.length - 1) i = root.entries.length - 1
    root.selectedIndex = i
  }

  function selectCurrent() {
    if (root.entries.length === 0) return
    root.selectEntry(root.entries[root.selectedIndex])
  }

  function selectEntry(line) {
    copyProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", root.entryId(line)]
    copyProc.running = false
    copyProc.running = true
    root.hide()
  }

  Process {
    id: listProc
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.entries = text.split("\n").filter(l => l.length > 0)
        if (root.selectedIndex > root.entries.length - 1)
          root.selectedIndex = Math.max(0, root.entries.length - 1)
      }
    }
  }

  Process { id: copyProc }

  IpcHandler {
    target: "clipboard"
    function toggle(): void { root.toggle() }
  }
}
