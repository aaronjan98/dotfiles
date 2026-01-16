pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  // Public state
  property bool ok: false
  property int percent: 0
  property bool muted: false
  property bool headphones: false

  // Debug (optional)
  property string lastVolLine: ""
  property string lastEventLine: ""

  readonly property string wpctlPath: "/run/current-system/sw/bin/wpctl"

  // -----------------------
  // Fast path: volume only
  // -----------------------
  function refreshVolume() {
    volProc.running = true
  }

  // Slow path: headphones detection (optional)
  function refreshInspect() {
    inspectProc.running = true
  }

  // For your hotkeys: unmutes then changes volume
  // deltaPercent is an integer, e.g. +5 / -5
  function setDelta(deltaPercent) {
    var d = parseInt(deltaPercent)
    if (isNaN(d) || d === 0) return

    // wpctl often changes volume without unmuting;
    // explicitly unmute first for the UX you want.
    // Then set-volume by +/-.
    cmdProc.command = ["sh", "-c",
      root.wpctlPath + " set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null; " +
      root.wpctlPath + " set-volume @DEFAULT_AUDIO_SINK@ " + Math.abs(d) + "%"+ (d > 0 ? "+" : "-") + " 2>/dev/null"
    ]
    cmdProc.running = true

    // Ask for a refresh quickly (subscribe should fire too, but this feels instant)
    queueRefresh()
  }

  // -----------------------
  // Subscribe debouncing
  // -----------------------
  property bool _refreshQueued: false
  property var _debounce: Timer {
    interval: 60
    repeat: false
    onTriggered: {
      root._refreshQueued = false
      root.refreshVolume()
    }
  }

  function queueRefresh() {
    if (root._refreshQueued) return
    root._refreshQueued = true
    _debounce.restart()
  }

  Component.onCompleted: {
    refreshVolume()
    refreshInspect()
    subProc.running = true
  }

  // -----------------------
  // Parsing helpers
  // -----------------------
  function computePercentFromLine(line) {
    // expected tokens: "Volume:" "<float>" ["[MUTED]"]
    var tokens = (line || "").trim().split(/\s+/)
    for (var i = 0; i < tokens.length; i++) {
      var v = parseFloat(tokens[i])
      if (!isNaN(v)) {
        var p = Math.round(v * 100)
        if (p < 0) p = 0
        if (p > 150) p = 150
        return p
      }
    }
    return 0
  }

  function computeMutedFromLine(line) {
    return (line || "").indexOf("MUTED") !== -1
  }

  function computeHeadphones(text) {
    var t = (text || "").toLowerCase()
    return (t.indexOf("headphone") !== -1) || (t.indexOf("headset") !== -1)
  }

  // -----------------------
  // Processes
  // -----------------------
  property var volProc: Process {
    command: ["sh", "-c", root.wpctlPath + " get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true"]

    stdout: SplitParser {
      onRead: data => {
        var line = (data || "").trim()
        if (!line) return

        root.lastVolLine = line
        root.percent = root.computePercentFromLine(line)
        root.muted = root.computeMutedFromLine(line)
        root.ok = true
      }
    }
    stderr: SplitParser { onRead: _ => {} }
  }

  // Run inspect rarely so it doesn’t slow volume updates
  property var inspectTimer: Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refreshInspect()
  }

  property var inspectProc: Process {
    command: ["sh", "-c", root.wpctlPath + " inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | head -n 80 || true"]

    stdout: SplitParser {
      property string acc: ""
      onRead: data => {
        if (data === null) return
        acc += data + "\n"
        root.headphones = root.computeHeadphones(acc)
      }
    }

    onRunningChanged: {
      if (!running) {
        if (stdout && stdout.acc !== undefined) stdout.acc = ""
      }
    }

    stderr: SplitParser { onRead: _ => {} }
  }

  property var subProc: Process {
    command: ["sh", "-c", root.wpctlPath + " subscribe 2>/dev/null"]

    stdout: SplitParser {
      onRead: data => {
        var line = (data || "").trim()
        if (!line) return
        root.lastEventLine = line
        root.queueRefresh()
      }
    }

    stderr: SplitParser { onRead: _ => {} }

    onRunningChanged: {
      if (!running) restartTimer.restart()
    }
  }

  property var restartTimer: Timer {
    interval: 500
    repeat: false
    onTriggered: subProc.running = true
  }

  property var cmdProc: Process {
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }
}

