pragma Singleton

import QtQuick
import Quickshell.Io
import Quickshell

// Language state for the Kanata island's language sub-island (LangIsland.qml)
// and, eventually, the accent-type/accent-cycle scripts (Phase 2,
// project-memory/kanata-island.md). Quickshell OWNS the active language --
// clicking a language in the lang pill writes it to `stateFile`, a plain
// one-line text file. A FILE rather than an IPC call because `accent-type`
// will read it on the keystroke's critical path -- a `cat` is free, a
// `qs ipc` round-trip is not (see the doc's "Language state" section).
//
// `languages`/`variants` are read from accents.json, the single source of
// truth shared with the (not yet built) accent-* shell scripts via `jq` --
// per CONTEXT.md, the table must not be duplicated into both a QML literal
// and a JSON file.
Item {
  id: root
  visible: false

  readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/quickshell/accent-lang"
  readonly property string tableFile: Quickshell.env("HOME") + "/.config/quickshell/accents.json"

  // Defaults mirror accents.json so the lang pill renders correctly even
  // before the file loads (first frame) or if it's ever missing.
  property var languages: ["en", "es", "pt"]
  property var variants: ({})
  property string currentLang: "en"

  function setLang(code) {
    if (languages.indexOf(code) < 0 || code === currentLang) return
    currentLang = code
    _stateFile.setText(code + "\n")
  }

  FileView {
    id: _tableFile
    path: root.tableFile
    onLoaded: {
      try {
        var o = JSON.parse(text())
        if (o && Array.isArray(o.languages) && o.languages.length > 0) root.languages = o.languages
        if (o && o.variants) root.variants = o.variants
      } catch (e) { /* keep last-good defaults on a partial write */ }
    }
    // Missing accents.json just means the defaults above stand -- not a
    // reason to leave the lang pill without any entries.
    onLoadFailed: {}
  }

  FileView {
    id: _stateFile
    path: root.stateFile
    onLoaded: {
      var v = text().trim()
      if (v && root.languages.indexOf(v) >= 0) root.currentLang = v
    }
    // No file yet (first run on this machine) -- "en" default stands; the
    // first setLang() click creates it.
    onLoadFailed: {}
  }
}
