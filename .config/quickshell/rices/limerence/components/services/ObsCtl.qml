pragma Singleton

import QtQuick
import Quickshell.Io

// Backend for the OBS control popup (ObsIcon/ObsPopup). Talks to OBS over
// obs-websocket v5 via a long-lived helper process
// (nixos-config/scripts/obs-ctl-daemon.py) that speaks the raw JSON
// websocket protocol -- see that script's header comment for why a plain
// CLI wrapper (obs-cli / obs-cmd) wasn't enough. The daemon pushes a full
// state snapshot on stdout every time anything changes (recording toggled,
// mute toggled, scene switched, ...), so this popup updates live even when
// OBS itself -- not this popup -- is what changed something.
Item {
  id: root
  visible: false

  readonly property string daemonScript: "/home/aj/nixos-config/scripts/obs-ctl-daemon.py"
  readonly property string windowScript: "/home/aj/.config/hypr/scripts/obs-toggle"

  property bool connected: false
  property string error: ""
  property string obsVersion: ""

  property var recording: ({ active: false, paused: false, timecode: "00:00:00" })
  property var streaming: ({ active: false })
  property var virtualCam: ({ active: false })
  property var replayBuffer: ({ active: false })

  property string currentScene: ""
  property var scenes: []
  property var inputs: []   // [{name, muted, volumeMul}]

  property bool open: false
  function show() { root.open = true }
  function hide() { root.open = false }
  function toggle() { root.open = !root.open }

  function runWindowAction(action) {
    windowProc.running = false
    windowProc.command = [root.windowScript, action]
    windowProc.running = true
  }

  function toggleWindow() { runWindowAction("toggle") }
  function openWindow() { runWindowAction("open") }
  function hideWindow() { runWindowAction("hide") }
  function launchWindow() { runWindowAction("launch") }

  function send(obj) { proc.write(JSON.stringify(obj) + "\n") }

  function refresh() { send({ cmd: "refresh" }) }
  function toggleRecording() { send({ cmd: "recording_toggle" }) }
  function stopRecording() { send({ cmd: "recording_stop" }) }
  function togglePauseRecording() { send({ cmd: "recording_pause_toggle" }) }
  function toggleStreaming() { send({ cmd: "streaming_toggle" }) }
  function toggleVirtualCam() { send({ cmd: "vcam_toggle" }) }
  function toggleReplayBuffer() { send({ cmd: "replay_toggle" }) }
  function saveReplayBuffer() { send({ cmd: "replay_save" }) }
  function setScene(name) { send({ cmd: "scene_set", scene: name }) }
  function toggleInputMute(name) { send({ cmd: "input_mute_toggle", input: name }) }
  function setInputVolume(name, volumeMul) { send({ cmd: "input_set_volume", input: name, volumeMul: volumeMul }) }

  Process {
    id: proc
    command: [root.daemonScript]
    stdinEnabled: true
    running: true

    stdout: SplitParser {
      onRead: data => {
        const line = (data || "").trim()
        if (!line) return
        let obj
        try { obj = JSON.parse(line) } catch (e) { return }
        if (obj.transientError !== undefined) return   // best-effort command failure, nothing to sync

        root.connected = !!obj.connected
        root.error = obj.error || ""
        root.obsVersion = obj.obsVersion || ""
        if (obj.recording) root.recording = obj.recording
        if (obj.streaming) root.streaming = obj.streaming
        if (obj.virtualCam) root.virtualCam = obj.virtualCam
        if (obj.replayBuffer) root.replayBuffer = obj.replayBuffer
        root.currentScene = obj.currentScene || ""
        root.scenes = obj.scenes || []
        root.inputs = obj.inputs || []
      }
    }
    stderr: SplitParser { onRead: _ => {} }
  }

  Process {
    id: windowProc
    command: [root.windowScript, "toggle"]
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }

  IpcHandler {
    target: "obs"
    function toggle(): void { root.toggle() }
    function toggleRecording(): void { root.toggleRecording() }
    function toggleStreaming(): void { root.toggleStreaming() }
    function toggleWindow(): void { root.toggleWindow() }
    function openWindow(): void { root.openWindow() }
  }
}
