import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../services" 1.0 as Sv

Item {
  id: api

  required property QtObject parentWindow   // TopBar PanelWindow
  property bool open: false
  signal dismissed()

  // password / connect UI state
  property string passwordSsid: ""
  property bool showPassword: false
  property string errorText: ""
  property string connectingSsid: ""

  function requestClose() {
    dismissed() // TopBar sets wifiPopupOpen = false
  }

  function openPasswordFor(ssid) {
    errorText = ""
    passwordSsid = ssid
    showPassword = true
  }

  function clearPassword() {
    showPassword = false
    passwordSsid = ""
    errorText = ""
  }

  function beginConnect(ssid, password) {
    connectingSsid = ssid
    errorText = ""
    Sv.WifiNm.connect(ssid, password || "")
  }

  // -------------------------------------------------
  // SCRIM (fullscreen) – BEHIND popup
  // -------------------------------------------------
  PanelWindow {
    id: scrim
    screen: api.parentWindow.screen
    visible: api.open

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    // IMPORTANT: Scrim is lower than popup
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // IMPORTANT: never steal keyboard focus
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 0

    color: "transparent"

    Item {
      anchors.fill: parent
      focus: api.open

      Keys.onEscapePressed: api.requestClose()

      // click outside closes
      MouseArea {
        anchors.fill: parent
        onClicked: api.requestClose()
      }
    }
  }

  // -------------------------------------------------
  // POPUP as PanelWindow – ABOVE scrim, takes keyboard
  // -------------------------------------------------
  PanelWindow {
    id: pop
    screen: api.parentWindow.screen
    visible: api.open

    WlrLayershell.layer: WlrLayer.Overlay          // <-- ABOVE scrim
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
      if (visible) {
        focusRoot.forceActiveFocus()
        // Auto-refresh list when opening the popup
        Sv.WifiNm.rescan()
      }
      if (!visible) {
        api.clearPassword()
        api.connectingSsid = ""
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

      // Open anim
      opacity: api.open ? 1 : 0
      scale: api.open ? 1 : 0.92
      Behavior on opacity { NumberAnimation { duration: 140 } }
      Behavior on scale { NumberAnimation { duration: 140 } }

      // Ensure clicks inside do NOT close anything
      MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Item {
        id: focusRoot
        anchors.fill: parent
        focus: api.open

        Keys.onEscapePressed: {
          if (api.showPassword) api.clearPassword()
          else api.requestClose()
        }

        ColumnLayout {
          id: content
          anchors.fill: parent
          anchors.margins: 12
          spacing: 10

          // Header
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text { text: "Wi-Fi"; color: "white"; font.pixelSize: 14; font.weight: 600 }
            Item { Layout.fillWidth: true }
            Text { text: Sv.WifiNm.wifiEnabled ? "On" : "Off"; color: Qt.rgba(1,1,1,0.85); font.pixelSize: 12 }

            Rectangle {
              width: 44; height: 22; radius: 999
              color: Sv.WifiNm.wifiEnabled ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.08)
              border.width: 1; border.color: Qt.rgba(1,1,1,0.18)

              Rectangle {
                width: 18; height: 18; radius: 999
                y: 2
                x: Sv.WifiNm.wifiEnabled ? (parent.width - width - 2) : 2
                color: "white"
                Behavior on x { NumberAnimation { duration: 120 } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Sv.WifiNm.toggleWifi(!Sv.WifiNm.wifiEnabled)
              }
            }
          }

          // NEW: show what’s actually being used for routing
          Text {
            Layout.fillWidth: true
            text: (Sv.WifiNm.activeType && Sv.WifiNm.activeDevice)
              ? ("Active route: " + Sv.WifiNm.activeType + " (" + Sv.WifiNm.activeDevice + ")")
              : "Active route: (unknown)"
            color: Qt.rgba(1,1,1,0.75)
            font.pixelSize: 11
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            text: Sv.WifiNm.connected ? ("Connected: " + Sv.WifiNm.ssid) : "Not connected"
            color: Qt.rgba(1,1,1,0.9)
            font.pixelSize: 12
            elide: Text.ElideRight
          }

          Text {
            Layout.fillWidth: true
            visible: api.errorText.length > 0
            text: api.errorText
            color: Qt.rgba(1, 0.55, 0.55, 0.95)
            font.pixelSize: 11
            wrapMode: Text.Wrap
          }

          // Actions
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

              Text { anchors.centerIn: parent; text: Sv.WifiNm.scanning ? "Scanning…" : "Rescan"; color: "white"; font.pixelSize: 12 }

              MouseArea {
                anchors.fill: parent
                enabled: Sv.WifiNm.wifiEnabled && !Sv.WifiNm.scanning
                cursorShape: Qt.PointingHandCursor
                onClicked: Sv.WifiNm.rescan()
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

          // Network list
          Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            clip: true

            contentWidth: width
            contentHeight: listCol.implicitHeight

            ColumnLayout {
              id: listCol
              width: parent.width
              spacing: 6

              Repeater {
                model: Sv.WifiNm.networks

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 6

                  Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 10
                    color: modelData.active ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.10)
                    border.width: 1
                    border.color: Qt.rgba(1,1,1,0.15)

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: 8
                      spacing: 8

                      Text {
                        text:
                          (modelData.strength >= 75 ? "󰤨" :
                           modelData.strength >= 50 ? "󰤥" :
                           modelData.strength >= 25 ? "󰤢" : "󰤟")
                        color: "white"
                        font.pixelSize: 14
                        font.family: C.Appearance.iconFont
                      }

                      Text {
                        text: modelData.secure ? "󰌾" : ""
                        color: Qt.rgba(1,1,1,0.75)
                        font.pixelSize: 13
                        font.family: C.Appearance.iconFont
                      }

                      Text {
                        Layout.fillWidth: true
                        text: modelData.ssid
                        color: "white"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        font.weight: modelData.active ? 600 : 400
                      }

                      Text {
                        text: (api.connectingSsid === modelData.ssid) ? "…" : ""
                        color: Qt.rgba(1,1,1,0.75)
                        font.pixelSize: 12
                      }
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      enabled: Sv.WifiNm.wifiEnabled

                      onClicked: {
                        api.errorText = ""

                        if (modelData.active) {
                          Sv.WifiNm.disconnect()
                          api.clearPassword()
                          return
                        }

                        if (modelData.secure) {
                          api.openPasswordFor(modelData.ssid)
                          return
                        }

                        api.clearPassword()
                        api.beginConnect(modelData.ssid, "")
                      }
                    }
                  }

                  Rectangle {
                    visible: api.showPassword && api.passwordSsid === modelData.ssid
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? inner.implicitHeight + 20 : 0
                    opacity: visible ? 1 : 0
                    radius: 10
                    color: Qt.rgba(0,0,0,0.30)
                    border.width: 1
                    border.color: Qt.rgba(1,1,1,0.18)

                    ColumnLayout {
                      id: inner
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.top: parent.top
                      anchors.margins: 10
                      spacing: 8

                      Text {
                        Layout.fillWidth: true
                        text: "Password for: " + modelData.ssid
                        color: "white"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: 8
                        color: Qt.rgba(0,0,0,0.45)
                        border.width: 1
                        border.color: Qt.rgba(1,1,1,0.22)

                        TextInput {
                          id: pwLocal
                          anchors.fill: parent
                          anchors.margins: 8
                          color: "white"
                          echoMode: TextInput.Password
                          cursorVisible: true
                          font.pixelSize: 12
                          Component.onCompleted: pwLocal.forceActiveFocus()
                          Keys.onReturnPressed: api.beginConnect(modelData.ssid, pwLocal.text)
                          Keys.onEscapePressed: api.clearPassword()
                        }
                      }

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                          Layout.fillWidth: true
                          Layout.preferredHeight: 28
                          radius: 8
                          color: Qt.rgba(1,1,1,0.10)
                          border.width: 1
                          border.color: Qt.rgba(1,1,1,0.14)

                          Text { anchors.centerIn: parent; text: "Cancel"; color: "white"; font.pixelSize: 12 }
                          MouseArea { anchors.fill: parent; onClicked: api.clearPassword() }
                        }

                        Rectangle {
                          Layout.fillWidth: true
                          Layout.preferredHeight: 28
                          radius: 8
                          color: Qt.rgba(1,1,1,0.18)
                          border.width: 1
                          border.color: Qt.rgba(1,1,1,0.16)

                          Text { anchors.centerIn: parent; text: "Connect"; color: "white"; font.pixelSize: 12 }
                          MouseArea { anchors.fill: parent; onClicked: api.beginConnect(modelData.ssid, pwLocal.text) }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    Connections {
      target: Sv.WifiNm
      function onConnectFinished(ssid, success, message) {
        if (api.connectingSsid === ssid) api.connectingSsid = ""
        if (success) {
          api.clearPassword()
        } else {
          api.errorText = (message && message.length) ? message : "Failed to connect."
        }
      }
    }
  }
}

