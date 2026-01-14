pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
  id: root

  // --- public state ---
  property bool ok: true
  property bool wifiEnabled: true
  property bool connected: false
  property string ssid: ""
  property int strength: 0          // 0..100
  property string wifiDevice: ""

  // list of APs: [{ ssid, strength, secure, active }]
  property var networks: []

  property bool scanning: false

  function refresh() {
    wifiGeneralProc.running = true
    wifiActiveProc.running = true
    wifiDevProc.running = true
  }

  function rescan() {
    scanning = true
    wifiListProc.running = true
  }

  function runCmd(cmd) {
    cmdProc.command = ["sh", "-c", cmd]
    cmdProc.running = true
  }

  function toggleWifi(on) {
    runCmd("nmcli radio wifi " + (on ? "on" : "off"))
    refresh()
    // list refresh shortly after toggling
    rescan()
  }

  function disconnect() {
    if (!wifiDevice) return
    runCmd("nmcli dev disconnect " + wifiDevice)
    refresh()
  }

  // For open networks, or saved networks, password can be empty.
  function connect(ssid, password) {
    if (!ssid) return
    // Quote SSID safely
    const q = ssid.replace(/"/g, "\\\"")
    if (password && password.length > 0) {
      const pw = password.replace(/"/g, "\\\"")
      runCmd("nmcli dev wifi connect \"" + q + "\" password \"" + pw + "\"")
    } else {
      runCmd("nmcli dev wifi connect \"" + q + "\"")
    }
    // optimistic refresh
    refresh()
    // refresh list after a moment
    rescan()
  }

  // --- poll ---
  property var pollTimer: Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: {
    refresh()
    rescan()
  }

  // --- enabled/disabled ---
  property var wifiGeneralProc: Process {
    command: ["sh", "-c", "nmcli -t -f WIFI general"]
    stdout: SplitParser {
      onRead: data => {
        root.ok = true
        if (!data) return
        root.wifiEnabled = data.trim() === "enabled"
      }
    }
    stderr: SplitParser { onRead: _ => root.ok = false }
  }

  // --- active wifi: "SSID:SIGNAL" or empty ---
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
    stderr: SplitParser { onRead: _ => root.ok = false }
  }

  // --- wifi device name ---
  property var wifiDevProc: Process {
    command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE dev | awk -F: '$2==\"wifi\" {print $1; exit}'"]
    stdout: SplitParser {
      onRead: data => {
        root.ok = true
        root.wifiDevice = (data || "").trim()
      }
    }
    stderr: SplitParser { onRead: _ => root.ok = false }
  }

  // --- list networks ---
  // We ask for: IN-USE,SSID,SIGNAL,SECURITY in terse format.
  // SECURITY empty/-- => open. Otherwise secure.
  property var wifiListProc: Process {
    command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes"]
    stdout: SplitParser {
      property var rows: []
      onRead: data => {
        root.ok = true
        if (data === null) return
        const line = data.trim()
        if (!line) return

        // Format: "*:MyWifi:78:WPA2" OR ":Other:40:--"
        const parts = line.split(":")
        if (parts.length < 4) return

        const inUse = parts[0] === "*"
        const ssid = parts[1] || ""
        const sig = parseInt(parts[2])
        const sec = parts.slice(3).join(":")  // in case it contains ':'
        const secure = sec && sec !== "--"

        // ignore blank SSIDs
        if (!ssid) return

        rows.push({
          active: inUse,
          ssid: ssid,
          strength: isNaN(sig) ? 0 : sig,
          secure: secure
        })
      }

      // SplitParser doesn't always give an "end" event.
      // So we finalize on process finish using onRunningChanged below.
    }

    onRunningChanged: {
      if (!running) {
        // finalize
        scanning = false
        // use the captured rows from stdout parser
        const r = wifiListProc.stdout.rows || []
        // sort: active first, then strength desc
        r.sort((a, b) => {
          if (a.active !== b.active) return (b.active ? 1 : 0) - (a.active ? 1 : 0)
          return (b.strength - a.strength)
        })
        // keep top 12 for now
        root.networks = r.slice(0, 12)
        // clear buffer for next run
        wifiListProc.stdout.rows = []
      }
    }

    stderr: SplitParser {
      onRead: _ => {
        root.ok = false
        scanning = false
      }
    }
  }

  // --- command runner ---
  property var cmdProc: Process {
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }
}

