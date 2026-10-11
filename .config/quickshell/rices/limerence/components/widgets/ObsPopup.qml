import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../services" 1.0 as Sv

// OBS recording control popup. OBS remains the full scene/source editor; this
// panel exposes only the recording workflow used from the top bar.
Item {
  id: api

  required property QtObject parentWindow

  readonly property var presets: ["Screen", "Screen + Camera", "Camera Only"]

  function requestClose() { Sv.ObsCtl.hide() }

  function fmtTimecode(tc) {
    if (!tc) return "00:00:00"
    const dot = tc.indexOf(".")
    return dot < 0 ? tc : tc.slice(0, dot)
  }

  function sceneAvailable(name) {
    return Sv.ObsCtl.scenes.indexOf(name) >= 0
  }

  function inputFor(name) {
    for (let i = 0; i < Sv.ObsCtl.inputs.length; i++) {
      const input = Sv.ObsCtl.inputs[i]
      if (input.name === name) return input
    }
    return null
  }

  function inputAvailable(name) {
    return inputFor(name) !== null
  }

  function inputMuted(name) {
    const input = inputFor(name)
    return input ? !!input.muted : false
  }

  PanelWindow {
    id: scrim
    screen: api.parentWindow.screen
    visible: Sv.ObsCtl.open

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    color: "transparent"

    Item {
      anchors.fill: parent
      focus: Sv.ObsCtl.open
      Keys.onEscapePressed: api.requestClose()

      MouseArea {
        anchors.fill: parent
        onClicked: api.requestClose()
      }
    }
  }

  PanelWindow {
    id: pop
    screen: api.parentWindow.screen
    visible: Sv.ObsCtl.open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: Sv.ObsCtl.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    anchors.top: true
    anchors.left: true
    margins.top: C.Appearance.topH + 10
    margins.left: Math.max(0, api.parentWindow.screen.width - implicitWidth - 10)

    color: "transparent"
    implicitWidth: 330
    implicitHeight: panel.implicitHeight

    onVisibleChanged: {
      if (visible) {
        focusRoot.forceActiveFocus()
        Sv.ObsCtl.refresh()
      }
    }

    Rectangle {
      id: panel
      width: pop.implicitWidth
      radius: 14
      color: Qt.rgba(35/255, 26/255, 60/255, 0.97)
      border.width: 1
      border.color: Qt.rgba(210/255, 190/255, 255/255, 0.35)
      antialiasing: true

      implicitHeight: content.implicitHeight + 24

      opacity: Sv.ObsCtl.open ? 1 : 0
      scale: Sv.ObsCtl.open ? 1 : 0.92
      Behavior on opacity { NumberAnimation { duration: 140 } }
      Behavior on scale { NumberAnimation { duration: 140 } }

      MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => { mouse.accepted = true }
      }

      Item {
        id: focusRoot
        anchors.fill: parent
        focus: Sv.ObsCtl.open
        Keys.onEscapePressed: api.requestClose()

        ColumnLayout {
          id: content
          anchors.fill: parent
          anchors.margins: 12
          spacing: 12

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text { text: "OBS"; color: "white"; font.pixelSize: 14; font.weight: 600 }

            Text {
              text: Sv.ObsCtl.connected ? ("v" + Sv.ObsCtl.obsVersion) : "disconnected"
              color: Sv.ObsCtl.connected ? Qt.rgba(1,1,1,0.6) : Qt.rgba(1,0.55,0.55,0.9)
              font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            ActionButton {
              label: "Close"
              compact: true
              onTriggered: api.requestClose()
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            visible: !Sv.ObsCtl.connected
            spacing: 8

            Text {
              Layout.fillWidth: true
              text: {
                switch (Sv.ObsCtl.error) {
                  case "password_required": return "OBS WebSocket requires a password, but none is configured."
                  case "auth_failed": return "Couldn't authenticate with OBS's WebSocket server."
                  case "no_config": return "No obs-websocket config found. Launch OBS once and enable the WebSocket server."
                  default: return "OBS is not reachable. Launch it, then the controls will connect automatically."
                }
              }
              color: Qt.rgba(1,1,1,0.78)
              font.pixelSize: 12
              wrapMode: Text.Wrap
            }

            ActionButton {
              Layout.fillWidth: true
              label: "Launch OBS"
              onTriggered: Sv.ObsCtl.openWindow()
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ActionButton {
              Layout.fillWidth: true
              label: "Open OBS"
              onTriggered: Sv.ObsCtl.openWindow()
            }

            ActionButton {
              Layout.fillWidth: true
              label: "Hide OBS"
              onTriggered: Sv.ObsCtl.hideWindow()
            }
          }

          Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.10) }

          ColumnLayout {
            Layout.fillWidth: true
            enabled: Sv.ObsCtl.connected
            opacity: enabled ? 1 : 0.42
            spacing: 7

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text { text: "Recording"; color: Qt.rgba(1,1,1,0.9); font.pixelSize: 12; font.weight: 600 }
              Item { Layout.fillWidth: true }
              Text {
                text: Sv.ObsCtl.recording.paused ? "Paused " + api.fmtTimecode(Sv.ObsCtl.recording.timecode)
                  : Sv.ObsCtl.recording.active ? api.fmtTimecode(Sv.ObsCtl.recording.timecode)
                  : "Idle"
                color: Sv.ObsCtl.recording.active ? Qt.rgba(0.95,0.4,0.4,0.95) : Qt.rgba(1,1,1,0.65)
                font.pixelSize: 12
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              ActionButton {
                Layout.fillWidth: true
                label: (Sv.ObsCtl.recording.active || Sv.ObsCtl.recording.paused) ? "Stop" : "Start"
                danger: Sv.ObsCtl.recording.active || Sv.ObsCtl.recording.paused
                onTriggered: Sv.ObsCtl.toggleRecording()
              }

              ActionButton {
                Layout.preferredWidth: 92
                visible: Sv.ObsCtl.recording.active || Sv.ObsCtl.recording.paused
                label: Sv.ObsCtl.recording.paused ? "Resume" : "Pause"
                onTriggered: Sv.ObsCtl.togglePauseRecording()
              }
            }
          }

          Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.10) }

          ColumnLayout {
            Layout.fillWidth: true
            enabled: Sv.ObsCtl.connected
            opacity: enabled ? 1 : 0.42
            spacing: 7

            Text { text: "Preset"; color: Qt.rgba(1,1,1,0.9); font.pixelSize: 12; font.weight: 600 }

            Flow {
              Layout.fillWidth: true
              spacing: 6

              Repeater {
                model: api.presets

                PresetButton {
                  label: modelData
                  active: Sv.ObsCtl.currentScene === modelData
                  available: api.sceneAvailable(modelData)
                  onTriggered: Sv.ObsCtl.setScene(modelData)
                }
              }
            }
          }

          Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.10) }

          ColumnLayout {
            Layout.fillWidth: true
            enabled: Sv.ObsCtl.connected
            opacity: enabled ? 1 : 0.42
            spacing: 7

            Text { text: "Inputs"; color: Qt.rgba(1,1,1,0.9); font.pixelSize: 12; font.weight: 600 }

            InputToggle {
              label: "Mic"
              inputName: "Mic/Aux"
            }

            InputToggle {
              label: "Desktop audio"
              inputName: "Desktop Audio"
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Text {
                text: "Camera"
                color: Qt.rgba(1,1,1,0.86)
                font.pixelSize: 12
                Layout.fillWidth: true
              }

              Text {
                text: "preset"
                color: Qt.rgba(1,1,1,0.48)
                font.pixelSize: 12
              }
            }
          }

          Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.10) }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ActionButton {
              Layout.fillWidth: true
              label: "Refresh"
              onTriggered: Sv.ObsCtl.refresh()
            }

            ActionButton {
              Layout.fillWidth: true
              label: "Open OBS"
              onTriggered: Sv.ObsCtl.openWindow()
            }
          }
        }
      }
    }
  }

  component ActionButton: Rectangle {
    id: button
    property string label: ""
    property bool danger: false
    property bool compact: false
    signal triggered()

    implicitWidth: compact ? 64 : 96
    implicitHeight: compact ? 26 : 30
    radius: 9
    color: danger ? Qt.rgba(0.85,0.3,0.3,0.35) : Qt.rgba(1,1,1,0.12)
    border.width: 1
    border.color: Qt.rgba(1,1,1,0.15)

    Text {
      anchors.centerIn: parent
      text: button.label
      color: "white"
      font.pixelSize: button.compact ? 12 : 12
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: button.triggered()
    }
  }

  component PresetButton: Rectangle {
    id: button
    property string label: ""
    property bool active: false
    property bool available: true
    signal triggered()

    implicitWidth: labelText.implicitWidth + 20
    implicitHeight: 28
    radius: 10
    opacity: available ? 1 : 0.38
    color: active ? Qt.rgba(1,1,1,0.24) : Qt.rgba(1,1,1,0.10)
    border.width: 1
    border.color: active ? Qt.rgba(1,1,1,0.34) : Qt.rgba(1,1,1,0.15)

    Text {
      id: labelText
      anchors.centerIn: parent
      text: button.label
      color: "white"
      font.pixelSize: 12
      font.weight: button.active ? 600 : 400
    }

    MouseArea {
      anchors.fill: parent
      enabled: button.available
      cursorShape: Qt.PointingHandCursor
      onClicked: button.triggered()
    }
  }

  component InputToggle: RowLayout {
    id: row
    property string label: ""
    property string inputName: ""
    readonly property bool available: api.inputAvailable(inputName)
    readonly property bool muted: api.inputMuted(inputName)

    Layout.fillWidth: true
    spacing: 8
    opacity: available ? 1 : 0.45

    Text {
      text: row.label
      color: Qt.rgba(1,1,1,0.86)
      font.pixelSize: 12
      Layout.fillWidth: true
    }

    Text {
      text: row.available ? (row.muted ? "off" : "on") : "missing"
      color: row.available
        ? (row.muted ? Qt.rgba(1,0.55,0.55,0.9) : Qt.rgba(0.55,0.9,0.62,0.95))
        : Qt.rgba(1,1,1,0.48)
      font.pixelSize: 12
    }

    Rectangle {
      width: 42
      height: 22
      radius: 999
      color: !row.available ? Qt.rgba(1,1,1,0.08)
        : row.muted ? Qt.rgba(1,1,1,0.10)
        : Qt.rgba(0.4,0.8,0.5,0.35)
      border.width: 1
      border.color: Qt.rgba(1,1,1,0.18)

      Rectangle {
        width: 18
        height: 18
        radius: 999
        y: 2
        x: row.available && !row.muted ? parent.width - width - 2 : 2
        color: "white"
        Behavior on x { NumberAnimation { duration: 120 } }
      }

      MouseArea {
        anchors.fill: parent
        enabled: row.available
        cursorShape: Qt.PointingHandCursor
        onClicked: Sv.ObsCtl.toggleInputMute(row.inputName)
      }
    }
  }
}
