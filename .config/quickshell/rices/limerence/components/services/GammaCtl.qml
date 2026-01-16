pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  // Public UI state
  property bool enabled: false
  property int tempPercent: 0               // 0..100 UI slider
  property int kelvinDay: 6500              // “neutral/normal”
  property int kelvinNight: 3000            // “warmest”
  property string lastStatus: "off"
  property string lastError: ""

  // Paths (avoid PATH issues inside services)
  readonly property string hyprsunset: "/run/current-system/sw/bin/hyprsunset"
  readonly property string pkill: "/run/current-system/sw/bin/pkill"

  // Internal: last slider value (we apply on release)
  property int _pendingPercent: 0

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

  // Map 0..100 to kelvinDay..kelvinNight
  function percentToKelvin(p) {
    p = clamp(p, 0, 100)
    return Math.round(kelvinDay + (kelvinNight - kelvinDay) * (p / 100.0))
  }

  // Enable/disable the night-light service
  function setEnabled(on) {
    enabled = !!on
    lastError = ""

    if (!enabled) {
      stop()
      lastStatus = "off"
      return
    }

    _pendingPercent = tempPercent
    start(percentToKelvin(_pendingPercent))
  }

  // Live drag preview: update UI immediately, but DO NOT restart hyprsunset yet.
  function preview(p) {
    p = clamp(Math.round(p), 0, 100)
    tempPercent = p
    _pendingPercent = p
  }

  // Commit on release: apply exactly once to avoid flashing during drag.
  function commit() {
    if (!enabled) return
    const k = percentToKelvin(_pendingPercent)
    start(k)
  }

  // Best-effort stop any running hyprsunset instance.
  function stop() {
    killProc.command = [pkill, "-x", "hyprsunset"]
    killProc.running = true
  }

  // Start hyprsunset at the requested temperature.
  // We stop first so we don’t accumulate multiple processes.
  function start(kelvin) {
    stop()
    startDelay.kelvin = kelvin
    startDelay.restart()
    lastStatus = "on (" + kelvin + "K)"
  }

  // Small delay so pkill lands before starting again.
  property var startDelay: Timer {
    property int kelvin: 4500
    interval: 40
    repeat: false
    onTriggered: {
      sunProc.command = [root.hyprsunset, "-t", String(kelvin)]
      sunProc.running = true
    }
  }

  property var sunProc: Process {
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser {
      onRead: data => {
        if (!data) return
        const t = data.trim()
        if (!t) return
        root.lastError = t
        // If hyprsunset exits, Quickshell may still show lastStatus; we keep status simple.
      }
    }
  }

  property var killProc: Process {
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }
}

