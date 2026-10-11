pragma Singleton

import QtQuick
import Quickshell.Io

// Service managing hypridle lifecycle (auto dim / screen lock).
// When idleEnabled is true, hypridle is running (normal idle dim & lock).
// When idleEnabled is false (keepAwake is true), hypridle is stopped so the screen
// stays awake indefinitely.
Item {
  id: root
  visible: false

  property bool idleEnabled: true
  readonly property bool keepAwake: !idleEnabled

  function start() {
    startProc.running = false
    startProc.running = true
  }

  function stop() {
    stopProc.running = false
    stopProc.running = true
  }

  function toggle() {
    if (root.idleEnabled) {
      root.stop()
    } else {
      root.start()
    }
  }

  function refreshStatus() {
    if (statusProc.running) return
    statusProc.running = true
  }

  Component.onCompleted: {
    root.refreshStatus()
    pollTimer.running = true
  }

  Timer {
    id: pollTimer
    interval: 2500
    repeat: true
    onTriggered: root.refreshStatus()
  }

  Process {
    id: statusProc
    command: ["systemctl", "--user", "is-active", "hypridle"]
    stdout: SplitParser {
      onRead: data => {
        const line = (data || "").trim()
        if (line === "active") {
          root.idleEnabled = true
        } else if (line === "inactive" || line === "failed") {
          root.idleEnabled = false
        }
      }
    }
    stderr: SplitParser { onRead: _ => {} }
  }

  Process {
    id: startProc
    command: ["systemctl", "--user", "start", "hypridle"]
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
    onRunningChanged: {
      if (!running) root.refreshStatus()
    }
  }

  Process {
    id: stopProc
    command: ["systemctl", "--user", "stop", "hypridle"]
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
    onRunningChanged: {
      if (!running) root.refreshStatus()
    }
  }

  IpcHandler {
    target: "hypridle"
    function toggle(): void { root.toggle() }
    function start(): void { root.start() }
    function stop(): void { root.stop() }
    function isIdleEnabled(): bool { return root.idleEnabled }
    function isKeepAwake(): bool { return root.keepAwake }
  }
}
