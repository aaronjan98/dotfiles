pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  property bool ok: false
  property int percent: 0

  // internal state (no +/-/= output)
  property bool isCharging: false
  property bool isFull: false

  property string raw: "" // debug if you want

  function refresh() { proc.running = true }

  property var pollTimer: Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()

  property var proc: Process {
    command: ["sh", "-c", `
      for bat in /sys/class/power_supply/BAT0 /sys/class/power_supply/BAT1; do
        if [ -r "$bat/capacity" ]; then
          cap="$(cat "$bat/capacity")"
          st=""
          if [ -r "$bat/status" ]; then
            st="$(cat "$bat/status" || true)"
          fi
          printf "%s|%s" "$cap" "$st"
          exit 0
        fi
      done
      printf "?|"
    `]

    stdout: SplitParser {
      onRead: data => {
        const line = (data || "").trim()
        root.raw = line

        const parts = line.split("|")
        const capStr = parts[0] || "?"
        const st = (parts[1] || "").trim()

        if (capStr === "?" || capStr === "") {
          root.ok = false
          return
        }

        const p = parseInt(capStr)
        if (isNaN(p)) {
          root.ok = false
          return
        }

        root.percent = p
        root.isCharging = (st === "Charging")
        root.isFull = (st === "Full")
        root.ok = true
      }
    }

    stderr: SplitParser { onRead: _ => {} }
  }
}

