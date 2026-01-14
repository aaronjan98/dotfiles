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
  property int strength: 0
  property string wifiDevice: ""
  property var networks: []      // [{ssid,strength,secure,active}]
  property bool scanning: false

  signal connectFinished(string ssid, bool success, string message)

  // ---------------------------
  // helpers
  // ---------------------------
  function refresh() {
    wifiGeneralProc.running = true
    wifiActiveProc.running = true
    wifiDevProc.running = true
  }

  function rescan() {
    if (!wifiEnabled) return
    scanning = true
    wifiRescanProc.running = true
  }

  function toggleWifi(on) {
    cmdProc.command = ["nmcli", "radio", "wifi", (on ? "on" : "off")]
    cmdProc.running = true
    refresh()
    if (on) rescan()
  }

  function disconnect() {
    if (!wifiDevice) return
    cmdProc.command = ["nmcli", "dev", "disconnect", wifiDevice]
    cmdProc.running = true
    refresh()
  }

  // ---------------------------
  // queue runner (sequential nmcli commands)
  // ---------------------------
  property var _queue: []
  property string _queueSsid: ""
  property string _queueErr: ""
  property bool _queueHadError: false

  function runQueue(ssid, commands) {
    _queue = commands || []
    _queueSsid = ssid || ""
    _queueErr = ""
    _queueHadError = false
    queueProc.running = false
    runNext()
  }

  function runNext() {
    if (_queue.length === 0) {
      // done
      root.refresh()
      root.rescan()
      root.connectFinished(_queueSsid, !_queueHadError, _queueErr)
      return
    }
    const cmd = _queue.shift()
    queueProc._hadError = false
    queueProc._errMsg = ""
    queueProc.command = cmd
    queueProc.running = true
  }

  // ---------------------------
  // connect logic
  // ---------------------------
  function connect(targetSsid, password) {
    if (!targetSsid) return

    connectProc._ssid = targetSsid
    connectProc._hadError = false
    connectProc._errMsg = ""

    // First try the normal simple way
    var args = ["nmcli", "--wait", "15", "dev", "wifi", "connect", targetSsid]

    if (password && password.length > 0) {
      args.push("password")
      args.push(password)
    }

    if (wifiDevice && wifiDevice.length > 0) {
      args.push("ifname")
      args.push(wifiDevice)
    }

    connectProc._password = password || ""
    connectProc.command = args
    connectProc.running = true
  }

  // ---------------------------
  // polling
  // ---------------------------
  property var pollTimer: Timer {
    interval: 1200
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: {
    refresh()
    rescan()
  }

  // ---------------------------
  // state procs
  // ---------------------------
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

  property var wifiActiveProc: Process {
    // "yes:<ssid>:<signal>" or empty
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

  // ---------------------------
  // scan/list
  // ---------------------------
  property var wifiRescanProc: Process {
    command: ["nmcli", "dev", "wifi", "rescan"]
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
    onRunningChanged: { if (!running) listDelay.restart() }
  }

  property var listDelay: Timer {
    interval: 400
    repeat: false
    onTriggered: wifiListProc.running = true
  }

  property var wifiListProc: Process {
    command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list"]

    stdout: SplitParser {
      id: listParser
      property var rows: []
      onRead: data => {
        root.ok = true
        if (data === null) return
        const line = data.trim()
        if (!line) return

        const parts = line.split(":")
        if (parts.length < 4) return

        const inUse = parts[0] === "*"
        const ssid = parts[1] || ""
        const sig = parseInt(parts[2])
        const sec = parts.slice(3).join(":")
        const secure = sec && sec !== "--"
        if (!ssid) return

        rows.push({
          active: inUse,
          ssid: ssid,
          strength: isNaN(sig) ? 0 : sig,
          secure: secure
        })
      }
    }

    onRunningChanged: {
      if (!running) {
        scanning = false
        const r = listParser.rows || []

        // de-dupe by SSID: multiple BSSIDs show as repeats
        const map = {}
        for (let i = 0; i < r.length; i++) {
          const ap = r[i]
          const key = ap.ssid
          if (!map[key]) {
            map[key] = { ssid: ap.ssid, strength: ap.strength, secure: ap.secure, active: ap.active }
          } else {
            if (ap.strength > map[key].strength) map[key].strength = ap.strength
            map[key].secure = map[key].secure || ap.secure
            map[key].active = map[key].active || ap.active
          }
        }

        const deduped = Object.values(map)
        deduped.sort((a, b) => {
          if (a.active !== b.active) return (b.active ? 1 : 0) - (a.active ? 1 : 0)
          if (b.strength !== a.strength) return b.strength - a.strength
          return (a.ssid || "").localeCompare(b.ssid || "")
        })

        root.networks = deduped.slice(0, 12)
        listParser.rows = []
      }
    }

    stderr: SplitParser {
      onRead: _ => {
        root.ok = false
        scanning = false
      }
    }
  }

  // ---------------------------
  // connect primary attempt
  // ---------------------------
  property var connectProc: Process {
    property string _ssid: ""
    property string _password: ""
    property bool _hadError: false
    property string _errMsg: ""

    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser {
      onRead: data => {
        if (!data) return
        const t = data.trim()
        if (!t) return
        connectProc._hadError = true
        connectProc._errMsg = t
      }
    }

    onRunningChanged: {
      if (!running) {
        // If success, finish normally
        if (!connectProc._hadError) {
          root.refresh()
          root.rescan()
          root.connectFinished(connectProc._ssid, true, "")
          return
        }

        // Fallback when NM complains about missing key-mgmt (broken/partial saved profile)
        const msg = connectProc._errMsg || ""
        const ssid = connectProc._ssid
        const pw = connectProc._password

        if (msg.indexOf("key-mgmt") !== -1 && pw && pw.length > 0) {
          // Explicitly define wpa-psk connection and bring it up.
          // We use a distinct con-name to avoid reusing a broken profile.
          const conName = "qs-" + ssid

          var cmds = []

          // Try to delete any existing conName silently (ignore failure)
          cmds.push(["nmcli", "connection", "delete", conName])

          // Add wifi connection
          // nmcli connection add type wifi ifname <dev> con-name <name> ssid <ssid>
          if (root.wifiDevice && root.wifiDevice.length > 0) {
            cmds.push(["nmcli", "connection", "add", "type", "wifi",
                       "ifname", root.wifiDevice,
                       "con-name", conName,
                       "ssid", ssid])
          } else {
            cmds.push(["nmcli", "connection", "add", "type", "wifi",
                       "con-name", conName,
                       "ssid", ssid])
          }

          // Set WPA2 PSK explicitly
          cmds.push(["nmcli", "connection", "modify", conName,
                     "wifi-sec.key-mgmt", "wpa-psk",
                     "wifi-sec.psk", pw])

          // Bring it up
          cmds.push(["nmcli", "--wait", "15", "connection", "up", conName])

          // run queue
          root._queueErr = ""
          root._queueHadError = false
          runQueue(ssid, cmds)
          return
        }

        // Otherwise, report original error
        root.refresh()
        root.rescan()
        root.connectFinished(connectProc._ssid, false, connectProc._errMsg)
      }
    }
  }

  // ---------------------------
  // queue proc for fallback
  // ---------------------------
  property var queueProc: Process {
    property bool _hadError: false
    property string _errMsg: ""

    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser {
      onRead: data => {
        if (!data) return
        const t = data.trim()
        if (!t) return
        queueProc._hadError = true
        queueProc._errMsg = t
      }
    }

    onRunningChanged: {
      if (!running) {
        if (queueProc._hadError) {
          root._queueHadError = true
          // keep the last non-empty error
          root._queueErr = queueProc._errMsg
        }
        runNext()
      }
    }
  }

  // ---------------------------
  // generic cmd proc
  // ---------------------------
  property var cmdProc: Process {
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }
}

