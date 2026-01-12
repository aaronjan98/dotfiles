pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id: mem

  // Same location my scripts use
  readonly property string runtimeDir: {
    const v = Quickshell.env("XDG_RUNTIME_DIR")
    return (v && ("" + v).length > 0) ? ("" + v) : "/tmp"
  }
  readonly property string stateDir: runtimeDir + "/hypr-domain-last"
  readonly property string lastPath: stateDir + "/last.txt"         // dom=slot
  readonly property string visitedPath: stateDir + "/visited.txt"   // dom per line

  // QtObject can't have children unless assigned to a property.
  // So we store FileViews as properties.
  property var lastView: FileView {
    path: mem.lastPath
    watchChanges: true
    printErrors: false
  }

  property var visitedView: FileView {
    path: mem.visitedPath
    watchChanges: true
    printErrors: false
  }

  function _lastText() {
    // FileView APIs can differ slightly; this pattern works with the common "text()" getter.
    try { return "" + mem.lastView.text() } catch (e) { return "" }
  }

  function _visitedText() {
    try { return "" + mem.visitedView.text() } catch (e) { return "" }
  }

  function _parseLastMap() {
    const t = _lastText()
    const map = ({})
    for (const raw of t.split("\n")) {
      const line = raw.trim()
      if (!line) continue
      const parts = line.split("=")
      if (parts.length !== 2) continue
      const dom = parseInt(parts[0], 10)
      const slot = parseInt(parts[1], 10)
      if (!Number.isFinite(dom) || !Number.isFinite(slot)) continue
      map[dom] = slot
    }
    return map
  }

  function lastSlot(dom) {
    const map = _parseLastMap()
    const v = map[dom]
    if (!Number.isFinite(v)) return 1
    return Math.max(1, Math.min(9, v))
  }

  function setLastSlot(dom, slot) {
    slot = Math.max(1, Math.min(9, slot))

    const map = _parseLastMap()
    map[dom] = slot

    const doms = Object.keys(map)
      .map(x => parseInt(x, 10))
      .filter(Number.isFinite)
      .sort((a, b) => a - b)

    const lines = doms.map(d => `${d}=${map[d]}`)
    // common setter is setText(...)
    try { mem.lastView.setText(lines.join("\n") + (lines.length ? "\n" : "")) } catch (e) {}
  }

  function ensureVisited(dom) {
    const t = _visitedText()
    const set = new Set()
    for (const raw of t.split("\n")) {
      const v = parseInt(raw.trim(), 10)
      if (Number.isFinite(v)) set.add(v)
    }

    if (!set.has(dom)) {
      set.add(dom)
      const doms = Array.from(set).sort((a, b) => a - b)
      try { mem.visitedView.setText(doms.join("\n") + "\n") } catch (e) {}
    }
  }
}

