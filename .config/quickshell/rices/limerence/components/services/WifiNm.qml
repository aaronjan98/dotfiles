pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  // Public state
  property bool wifiEnabled: true
  property bool connected: false
  property string ssid: ""
  property int strength: 0        // 0..100
  property string wifiDevice: ""

  // For a simple "error" state if nmcli is unavailable or fails
  property bool ok: true

  function refresh() {
    wifiGeneralProc.running = true
    wifiActiveProc.running = true
    wifiDevProc.running = true
  }

  function runCmd(cmd) {
    cmdProc.command = ["sh", "-c", cmd]
    cmdProc.running = true
  }

  function toggleWifi(on) {
    runCmd("nmcli radio wifi " + (on ? "on" : "off"))
    refresh()
  }

  function disconnect() {
    if (!wifiDevice) return
    runCmd("nmcli dev disconnect " + wifiDevice)
    refresh()
  }

  // --- polling ---
  property var pollTimer: Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: refresh()

  // --- nmcli: general wifi enabled/disabled ---
  property var wifiGeneralProc: Process {
    command: ["sh", "-c", "nmcli -t -f WIFI general"]
    stdout: SplitParser {
      onRead: data => {
        root.ok = true
        if (!data) return
        root.wifiEnabled = data.trim() === "enabled"
      }
    }
    stderr: SplitParser {
      onRead: _ => { root.ok = false }
    }
  }

  // --- nmcli: active wifi "SSID:SIGNAL" (empty if none) ---
  property var wifiActiveProc: Process {
    command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | sed -n 's/^yes://p' | head -n1"]
    stdout: SplitParser {
      onRead: data => {
        root.ok = true
        const line = (data || "").trim()
        if (!line) {
          root.connected = false
          root.ssid = ""
          root.strength = 0
          return
        }
        const parts = line.split(":")
        root.connected = true
        root.ssid = parts[0] || ""
        const sig = parseInt(parts[1])
        root.strength = isNaN(sig) ? 0 : sig
      }
    }
    stderr: SplitParser {
      onRead: _ => { root.ok = false }
    }
  }

  // --- nmcli: detect wifi device name ---
  property var wifiDevProc: Process {
    command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\" {print $1; exit}'"]
    stdout: SplitParser {
      onRead: data => {
        root.ok = true
        root.wifiDevice = (data || "").trim()
      }
    }
    stderr: SplitParser {
      onRead: _ => { root.ok = false }
    }
  }

  // --- command runner ---
  property var cmdProc: Process {
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }
}

