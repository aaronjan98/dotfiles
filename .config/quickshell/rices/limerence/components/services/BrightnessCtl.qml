pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property bool ok: true

  // Hardcode your known devices
  property string screenDev: "amdgpu_bl1"
  property string kbdDev: "tpacpi::kbd_backlight"
  property bool hasKbd: true

  // Screen
  property int screenCur: 0
  property int screenMax: 255
  property int screenPercent: 0

  // Keyboard
  property int kbdCur: 0
  property int kbdMax: 2
  property int kbdPercent: 0

  // Optional “restore on resume” behavior
  property int desiredKbdStep: -1
  property bool _restoreArmed: false

  // Debug
  property string lastScreenLine: ""
  property string lastKbdLine: ""

  readonly property string sh: "/run/current-system/sw/bin/sh"
  readonly property string brightnessctl: "/run/current-system/sw/bin/brightnessctl"

  function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

  function refresh() {
    screenInfoProc.running = true
    if (hasKbd) kbdInfoProc.running = true
  }

  function setScreenPercent(p) {
    p = clamp(Math.round(p), 0, 100)
    cmdProc.command = [sh, "-c",
      brightnessctl + " -d " + screenDev + " set " + p + "% >/dev/null 2>&1 || true"
    ]
    cmdProc.running = true
    screenInfoProc.running = true
  }

  // Keyboard is step-based; still accept a 0-100 slider, map to 0..kbdMax
  function setKbdPercent(p) {
    if (!hasKbd || kbdMax <= 0) return
    p = clamp(Math.round(p), 0, 100)

    var step = Math.round((p / 100.0) * kbdMax)
    step = clamp(step, 0, kbdMax)

    desiredKbdStep = step
    _restoreArmed = true

    cmdProc.command = [sh, "-c",
      brightnessctl + " -d " + kbdDev + " set " + step + " >/dev/null 2>&1 || true"
    ]
    cmdProc.running = true
    kbdInfoProc.running = true
  }

  function maybeRestoreKbd() {
    if (!hasKbd || !_restoreArmed || desiredKbdStep < 0) return
    if (kbdCur === 0 && desiredKbdStep > 0) {
      cmdProc.command = [sh, "-c",
        brightnessctl + " -d " + kbdDev + " set " + desiredKbdStep + " >/dev/null 2>&1 || true"
      ]
      cmdProc.running = true
      kbdInfoProc.running = true
    }
  }

  // Lightweight poll to pick up hardware key changes + restore after resume
  property var pollTimer: Timer {
    interval: 800
    running: true
    repeat: true
    onTriggered: {
      refresh()
      maybeRestoreKbd()
    }
  }

  Component.onCompleted: refresh()

  // Parse your actual output format:
  // name,class,cur,XX%,max
  function parseInfo(line) {
    const t = (line || "").trim()
    if (!t) return null
    const parts = t.split(",")
    if (parts.length < 5) return null

    const cur = parseInt(parts[2])
    const percentStr = (parts[3] || "").replace("%", "")
    const pct = parseInt(percentStr)
    const maxv = parseInt(parts[4])

    if (isNaN(cur) || isNaN(maxv)) return null

    // If pct is missing, compute as fallback
    const pctFinal = isNaN(pct) ? Math.round(100 * (cur / (maxv > 0 ? maxv : 1))) : pct
    return { cur: cur, max: (maxv > 0 ? maxv : 1), pct: clamp(pctFinal, 0, 100) }
  }

  property var screenInfoProc: Process {
    command: [sh, "-c", brightnessctl + " -m -d " + root.screenDev + " info 2>/dev/null || true"]
    stdout: SplitParser {
      onRead: data => {
        const line = (data || "").trim()
        if (!line) return
        root.lastScreenLine = line
        const v = root.parseInfo(line)
        if (!v) return
        root.ok = true
        root.screenCur = v.cur
        root.screenMax = v.max
        root.screenPercent = v.pct
      }
    }
    stderr: SplitParser { onRead: _ => root.ok = false }
  }

  property var kbdInfoProc: Process {
    command: [sh, "-c", brightnessctl + " -m -d " + root.kbdDev + " info 2>/dev/null || true"]
    stdout: SplitParser {
      onRead: data => {
        const line = (data || "").trim()
        if (!line) return
        root.lastKbdLine = line
        const v = root.parseInfo(line)
        if (!v) {
          root.hasKbd = false
          return
        }
        root.hasKbd = true
        root.kbdCur = v.cur
        root.kbdMax = v.max
        root.kbdPercent = Math.round(100 * (root.kbdCur / (root.kbdMax > 0 ? root.kbdMax : 1)))

        if (root.desiredKbdStep < 0) {
          root.desiredKbdStep = root.kbdCur
          root._restoreArmed = true
        }
      }
    }
    stderr: SplitParser { onRead: _ => {} }
  }

  property var cmdProc: Process {
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }
}

