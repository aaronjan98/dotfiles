pragma Singleton
import QtQuick
import Quickshell.Io

// Backend for the live note-taking recorder toggle
// (~/nixos-config/scripts/notetake-record.sh). Just tracks on/off state for
// NotetakeIcon.qml -- fold-in/transcription happens via the agent running
// notetake-foldin.sh directly in conversation, not through this UI.
QtObject {
  id: root

  readonly property string recordScript: "/home/aj/nixos-config/scripts/notetake-record.sh"

  property bool recording: false

  function start() { startProc.running = true }
  function stop() { stopProc.running = true }
  function toggle() { root.recording ? root.stop() : root.start() }
  function refreshStatus() { statusProc.running = true }

  Component.onCompleted: {
    refreshStatus()
    pollTimer.running = true
  }

  property var pollTimer: Timer {
    interval: 2000
    repeat: true
    onTriggered: root.refreshStatus()
  }

  // "notetake: recording (segment: <path>)" / "notetake: not recording"
  property var statusProc: Process {
    command: [root.recordScript, "status"]
    stdout: SplitParser {
      onRead: data => {
        const line = (data || "").trim()
        if (!line) return
        root.recording = line.indexOf("notetake: recording") === 0
      }
    }
    stderr: SplitParser { onRead: _ => {} }
  }

  property var startProc: Process {
    command: [root.recordScript, "start"]
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
    onRunningChanged: if (!running) root.refreshStatus()
  }

  property var stopProc: Process {
    command: [root.recordScript, "stop"]
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
    onRunningChanged: if (!running) root.refreshStatus()
  }
}
