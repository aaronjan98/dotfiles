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

  // ---- accent panel (Phase 2: accent-type/accent-cycle/accent-commit) ----
  // Display-only mirror of what the shell scripts already decided -- the
  // scripts own accent-state.json and the actual typing on the critical
  // path; these three functions (called via AccentIpc's IpcHandler) only
  // ever update what the panel SHOWS. Deliberately not re-deriving the
  // variant list from `variants`/`currentLang` here: the script already
  // resolved language + table lookup once, and passing that exact list
  // through means the panel can never show something different from what
  // was actually typed.
  property bool panelVisible: false
  property string activeBase: ""
  property var activeVariants: []
  property int activeIndex: 0

  // NO inactivity auto-commit. A fixed timer was tried first (1500ms per
  // the doc's original suggestion, then 4000ms) and rejected both times:
  // the panel/submap should stay open until the user deliberately commits
  // (Return/Escape/space, see accent-commit) or starts a new pick (another
  // AltGr+vowel, which re-enters via accent-type regardless of whatever
  // state this was left in) -- not vanish on an arbitrary clock the user
  // has no control over. 1500ms was confirmed (by reproducing it directly)
  // to fire mid-glance, before a real person could even move their hand to
  // the arrow keys; 4000ms still read as "the same behaviour" to the user,
  // i.e. still an arbitrary number fighting against however long they
  // actually take, rather than responding to what they're doing.
  //
  // The real tradeoff this accepts: if you truly walk away mid-pick, the
  // `accent` submap stays engaged and arrow keys keep going to accent-cycle
  // instead of the app until you come back and press Return/Escape/space.
  // No current mechanism commits on "any other keystroke" -- Hyprland
  // submap binds are an explicit allow-list (see conf.d/20-binds.conf), not
  // a catch-all, so there is nothing to hook "pressed a totally different
  // key" onto without enumerating every key on the keyboard individually.

  function show(base, variantsCsv, index) {
    activeBase = base
    activeVariants = variantsCsv.length > 0 ? variantsCsv.split(",") : []
    activeIndex = index
    panelVisible = true
  }

  function select(index) {
    if (!panelVisible) return
    activeIndex = index
  }

  function hide() {
    panelVisible = false
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
