import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../../config" as C

Item {
  id: api

  required property QtObject parentWindow
  property bool open: false
  signal dismissed()

  function requestClose() { dismissed() }

  // -------------------------------------------------
  // Command runner (Blueman)
  // -------------------------------------------------
  property var _cmd: Process {
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }

  function runCmd(args) {
    _cmd.command = args
    _cmd.running = true
  }

  // convenience
  function adapter() { return Bluetooth.defaultAdapter }

  function isPaired(d) {
    return d && (d.bonded || d.paired)
  }

  // -------------------------------------------------
  // Recently-seen tracking (Phase 2)
  // -------------------------------------------------
  property var lastSeenByKey: ({})                 // key -> ms timestamp
  property int recentWindowMs: 2 * 60 * 1000       // 2 minutes

  function nowMs() { return Date.now() }

  function deviceKey(d) {
    if (!d) return ""
    // try common identity fields (the first stable one wins)
    if (d.address !== undefined && d.address !== null && String(d.address).length) return String(d.address)
    if (d.mac !== undefined && d.mac !== null && String(d.mac).length) return String(d.mac)
    if (d.id !== undefined && d.id !== null && String(d.id).length) return String(d.id)
    if (d.path !== undefined && d.path !== null && String(d.path).length) return String(d.path)
    // last resort (not ideal)
    return d.name ? ("name:" + String(d.name)) : ""
  }

  function markNearbySeen() {
    const ad = adapter()
    if (!ad || !ad.enabled || !ad.discovering) return

    const ds = Bluetooth.devices ? Bluetooth.devices.values : []
    const t = nowMs()

    for (let i = 0; i < ds.length; i++) {
      const d = ds[i]
      if (!d) continue
      if (isPaired(d)) continue

      const k = deviceKey(d)
      if (!k) continue
      lastSeenByKey[k] = t
    }

    // prune old entries
    for (const k in lastSeenByKey) {
      if ((t - lastSeenByKey[k]) > recentWindowMs) delete lastSeenByKey[k]
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: api.markNearbySeen()
  }

  function pairedDevices() {
    const ds = Bluetooth.devices ? Bluetooth.devices.values : []
    const out = ds.filter(d => isPaired(d))
    out.sort((a, b) => (b.connected - a.connected) || ((a.name || "").localeCompare(b.name || "")))
    return out.slice(0, 12)
  }

  function recentDevices() {
    const ds = Bluetooth.devices ? Bluetooth.devices.values : []
    const t = nowMs()

    const out = ds.filter(d => {
      if (!d) return false
      if (isPaired(d)) return false
      const k = deviceKey(d)
      if (!k) return false
      const seen = lastSeenByKey[k]
      return seen && (t - seen) <= recentWindowMs
    })

    out.sort((a, b) => {
      const ka = deviceKey(a), kb = deviceKey(b)
      const ta = lastSeenByKey[ka] || 0
      const tb = lastSeenByKey[kb] || 0
      if (tb !== ta) return tb - ta
      return (a.name || "").localeCompare(b.name || "")
    })

    return out.slice(0, 12)
  }

  function ageLabelFor(d) {
    const k = deviceKey(d)
    const t = lastSeenByKey[k] || 0
    if (!t) return ""
    const age = Math.floor((nowMs() - t) / 1000)
    if (age < 60) return age + "s"
    return Math.floor(age / 60) + "m"
  }

  // ---------------------------
  // SCRIM
  // ---------------------------
  PanelWindow {
    id: scrim
    screen: api.parentWindow.screen
    visible: api.open

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
      focus: api.open
      Keys.onEscapePressed: api.requestClose()

      MouseArea {
        anchors.fill: parent
        onClicked: api.requestClose()
      }
    }
  }

  // ---------------------------
  // POPUP
  // ---------------------------
  PanelWindow {
    id: pop
    screen: api.parentWindow.screen
    visible: api.open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: api.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    anchors.top: true
    anchors.left: true

    // Position: below top bar, right-aligned to screen
    margins.top: C.Appearance.topH + 10
    margins.left: Math.max(0, api.parentWindow.screen.width - implicitWidth - 10)

    color: "transparent"

    implicitWidth: 360
    implicitHeight: panel.implicitHeight

    onVisibleChanged: {
      if (visible) focusRoot.forceActiveFocus()
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

      opacity: api.open ? 1 : 0
      scale: api.open ? 1 : 0.92
      Behavior on opacity { NumberAnimation { duration: 140 } }
      Behavior on scale { NumberAnimation { duration: 140 } }

      MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Item {
        id: focusRoot
        anchors.fill: parent
        focus: api.open

        Keys.onEscapePressed: api.requestClose()

        ColumnLayout {
          id: content
          anchors.fill: parent
          anchors.margins: 12
          spacing: 10

          // Header
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text { text: "Bluetooth"; color: "white"; font.pixelSize: 14; font.weight: 600 }
            Item { Layout.fillWidth: true }

            Text {
              text: (api.adapter() && api.adapter().enabled) ? "On" : "Off"
              color: Qt.rgba(1,1,1,0.85)
              font.pixelSize: 12
            }

            // Toggle enabled
            Rectangle {
              width: 44; height: 22; radius: 999
              color: (api.adapter() && api.adapter().enabled) ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.08)
              border.width: 1; border.color: Qt.rgba(1,1,1,0.18)

              Rectangle {
                width: 18; height: 18; radius: 999
                y: 2
                x: (api.adapter() && api.adapter().enabled) ? (parent.width - width - 2) : 2
                color: "white"
                Behavior on x { NumberAnimation { duration: 120 } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  const ad = api.adapter()
                  if (ad) ad.enabled = !ad.enabled
                }
              }
            }
          }

          // Discovering row
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text { text: "Discovering"; color: Qt.rgba(1,1,1,0.9); font.pixelSize: 12 }
            Item { Layout.fillWidth: true }

            Text {
              text: (api.adapter() && api.adapter().discovering) ? "On" : "Off"
              color: Qt.rgba(1,1,1,0.75)
              font.pixelSize: 12
            }

            Rectangle {
              width: 44; height: 22; radius: 999
              color: (api.adapter() && api.adapter().discovering) ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.08)
              border.width: 1; border.color: Qt.rgba(1,1,1,0.18)

              Rectangle {
                width: 18; height: 18; radius: 999
                y: 2
                x: (api.adapter() && api.adapter().discovering) ? (parent.width - width - 2) : 2
                color: "white"
                Behavior on x { NumberAnimation { duration: 120 } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: api.adapter() && api.adapter().enabled
                onClicked: {
                  const ad = api.adapter()
                  if (ad) ad.discovering = !ad.discovering
                }
              }
            }
          }

          // Action buttons
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 28
              radius: 10
              color: Qt.rgba(1,1,1,0.12)
              border.width: 1
              border.color: Qt.rgba(1,1,1,0.15)

              Text {
                anchors.centerIn: parent
                text: (api.adapter() && api.adapter().discovering) ? "Stop scan" : "Scan"
                color: "white"
                font.pixelSize: 12
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: api.adapter() && api.adapter().enabled
                onClicked: {
                  const ad = api.adapter()
                  if (ad) ad.discovering = !ad.discovering
                }
              }
            }

            Rectangle {
              Layout.preferredWidth: 110
              Layout.preferredHeight: 28
              radius: 10
              color: Qt.rgba(1,1,1,0.12)
              border.width: 1
              border.color: Qt.rgba(1,1,1,0.15)

              Text { anchors.centerIn: parent; text: "Close"; color: "white"; font.pixelSize: 12 }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: api.requestClose()
              }
            }
          }

          // Summary
          Text {
            Layout.fillWidth: true
            font.pixelSize: 12
            color: Qt.rgba(1,1,1,0.85)
            text: {
              const ds = Bluetooth.devices ? Bluetooth.devices.values : []
              const n = ds.length
              let c = 0
              for (let i = 0; i < ds.length; i++) if (ds[i] && ds[i].connected) c++
              return (n === 1 ? "1 device" : (n + " devices")) + (c > 0 ? (" (" + c + " connected)") : "")
            }
          }

          // Device list
          Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 340
            clip: true
            contentWidth: width
            contentHeight: listCol.implicitHeight

            ColumnLayout {
              id: listCol
              width: parent.width
              spacing: 8

              // ---- Paired section header
              Text {
                Layout.fillWidth: true
                text: "Paired devices"
                color: Qt.rgba(1,1,1,0.9)
                font.pixelSize: 12
                font.weight: 600
              }

              Repeater {
                model: api.pairedDevices()

                Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  Layout.preferredHeight: 34
                  radius: 10
                  color: modelData && modelData.connected ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.10)
                  border.width: 1
                  border.color: Qt.rgba(1,1,1,0.15)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                      text: "󰂯"
                      color: "white"
                      font.pixelSize: 14
                      font.family: C.Appearance.iconFont
                    }

                    Text {
                      Layout.fillWidth: true
                      text: (modelData && modelData.name) ? modelData.name : "Unknown"
                      color: "white"
                      font.pixelSize: 12
                      elide: Text.ElideRight
                      font.weight: (modelData && modelData.connected) ? 600 : 400
                    }

                    Text {
                      text: (modelData && (modelData.paired || modelData.bonded)) ? "󰌾" : ""
                      color: Qt.rgba(1,1,1,0.75)
                      font.pixelSize: 13
                      font.family: C.Appearance.iconFont
                    }

                    Rectangle {
                      implicitWidth: 74
                      implicitHeight: 24
                      radius: 8
                      color: Qt.rgba(1,1,1,0.10)
                      border.width: 1
                      border.color: Qt.rgba(1,1,1,0.14)

                      Text {
                        anchors.centerIn: parent
                        text: (modelData && modelData.connected) ? "Disconnect" : "Connect"
                        color: "white"
                        font.pixelSize: 11
                      }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: api.adapter() && api.adapter().enabled && modelData
                        onClicked: modelData.connected = !modelData.connected
                      }
                    }

                    Rectangle {
                      visible: modelData && modelData.bonded
                      implicitWidth: 56
                      implicitHeight: 24
                      radius: 8
                      color: Qt.rgba(1,1,1,0.08)
                      border.width: 1
                      border.color: Qt.rgba(1,1,1,0.12)

                      Text { anchors.centerIn: parent; text: "Forget"; color: "white"; font.pixelSize: 11 }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.forget()
                      }
                    }
                  }
                }
              }

              // ---- Recently seen section header
              Text {
                Layout.fillWidth: true
                visible: api.adapter() && api.adapter().discovering
                text: "Recently seen (last " + Math.round(api.recentWindowMs / 60000) + " min)"
                color: Qt.rgba(1,1,1,0.9)
                font.pixelSize: 12
                font.weight: 600
              }

              Text {
                Layout.fillWidth: true
                visible: api.adapter() && api.adapter().enabled && !api.adapter().discovering
                text: "Turn on Discovering to find nearby devices."
                color: Qt.rgba(1,1,1,0.7)
                font.pixelSize: 11
                wrapMode: Text.Wrap
              }

              Repeater {
                visible: api.adapter() && api.adapter().discovering
                model: api.recentDevices()

                Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  Layout.preferredHeight: 34
                  radius: 10
                  color: Qt.rgba(1,1,1,0.10)
                  border.width: 1
                  border.color: Qt.rgba(1,1,1,0.15)

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                      text: "󰂯"
                      color: "white"
                      font.pixelSize: 14
                      font.family: C.Appearance.iconFont
                    }

                    Text {
                      Layout.fillWidth: true
                      text: (modelData && modelData.name) ? modelData.name : "Unknown"
                      color: "white"
                      font.pixelSize: 12
                      elide: Text.ElideRight
                    }

                    Text {
                      text: api.ageLabelFor(modelData)
                      color: Qt.rgba(1,1,1,0.65)
                      font.pixelSize: 11
                    }

                    Rectangle {
                      implicitWidth: 70
                      implicitHeight: 24
                      radius: 8
                      color: Qt.rgba(1,1,1,0.10)
                      border.width: 1
                      border.color: Qt.rgba(1,1,1,0.14)

                      Text { anchors.centerIn: parent; text: "Pair…"; color: "white"; font.pixelSize: 11 }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: api.adapter() && api.adapter().enabled
                        onClicked: api.runCmd(["blueman-assistant"])
                      }
                    }
                  }
                }
              }
            }
          }

          // Bottom: Open manager
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 10
            color: Qt.rgba(1,1,1,0.12)
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.15)

            Text { anchors.centerIn: parent; text: "Open Blueman Manager"; color: "white"; font.pixelSize: 12 }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: api.runCmd(["blueman-manager"])
            }
          }
        }
      }
    }
  }
}

