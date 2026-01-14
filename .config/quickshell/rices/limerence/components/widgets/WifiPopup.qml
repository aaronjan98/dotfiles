import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../services" as Sv

PanelWindow {
  id: win
  required property ShellScreen screen
  property bool open: false

  screen: screen

  anchors.top: true
  anchors.right: true
  // Popout appears just below the top bar
  margins.top: C.Appearance.topH + 6
  margins.right: 8

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  implicitWidth: 320
  implicitHeight: container.implicitHeight

  color: "transparent"
  visible: open

  // The window itself stays untransformed; we animate this inner container.
  Item {
    id: container
    anchors.fill: parent

    // animate open/close
    opacity: win.open ? 1 : 0
    scale: win.open ? 1 : 0.92

    Behavior on opacity { NumberAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 140 } }

    Rectangle {
      id: body
      anchors.fill: parent
      radius: 14
      color: Qt.rgba(35/255, 26/255, 60/255, 0.88)
      border.width: 1
      border.color: Qt.rgba(210/255, 190/255, 255/255, 0.35)
      antialiasing: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: "Wi-Fi"
            color: "white"
            font.pixelSize: 14
            font.weight: 600
          }

          Item { Layout.fillWidth: true }

          Text {
            text: Sv.WifiNm.wifiEnabled ? "On" : "Off"
            color: Qt.rgba(1,1,1,0.75)
            font.pixelSize: 12
          }

          // Simple toggle switch
          Rectangle {
            width: 44
            height: 22
            radius: 999
            color: Sv.WifiNm.wifiEnabled ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.08)
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.18)

            Rectangle {
              width: 18
              height: 18
              radius: 999
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

        Text {
          Layout.fillWidth: true
          text: Sv.WifiNm.connected ? ("Connected: " + Sv.WifiNm.ssid) : "Not connected"
          color: Qt.rgba(1,1,1,0.85)
          font.pixelSize: 12
          elide: Text.ElideRight
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Rectangle {
            Layout.preferredHeight: 28
            Layout.fillWidth: true
            radius: 10
            color: Qt.rgba(1,1,1,0.10)
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.12)

            Text {
              anchors.centerIn: parent
              text: Sv.WifiNm.scanning ? "Scanning…" : "Rescan"
              color: "white"
              font.pixelSize: 12
            }

            MouseArea {
              anchors.fill: parent
              enabled: Sv.WifiNm.wifiEnabled && !Sv.WifiNm.scanning
              cursorShape: Qt.PointingHandCursor
              onClicked: Sv.WifiNm.rescan()
            }
          }

          Rectangle {
            Layout.preferredHeight: 28
            Layout.preferredWidth: 110
            radius: 10
            color: Qt.rgba(1,1,1,0.10)
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.12)

            Text { anchors.centerIn: parent; text: "Disconnect"; color: "white"; font.pixelSize: 12 }

            MouseArea {
              anchors.fill: parent
              enabled: Sv.WifiNm.connected
              cursorShape: Qt.PointingHandCursor
              onClicked: Sv.WifiNm.disconnect()
            }
          }
        }

        // Networks list
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 6

          Repeater {
            model: Sv.WifiNm.networks

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 34
              radius: 10
              color: modelData.active ? Qt.rgba(1,1,1,0.14) : Qt.rgba(1,1,1,0.07)
              border.width: 1
              border.color: Qt.rgba(1,1,1,0.10)

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
                }

                Text {
                  text: modelData.secure ? "󰌾" : ""
                  color: Qt.rgba(1,1,1,0.75)
                  font.pixelSize: 13
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
                  text: modelData.active ? "Connected" : ""
                  color: Qt.rgba(1,1,1,0.60)
                  font.pixelSize: 11
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: Sv.WifiNm.wifiEnabled

                onClicked: {
                  if (modelData.active) {
                    Sv.WifiNm.disconnect()
                  } else {
                    // Tries saved/open networks without prompting.
                    Sv.WifiNm.connect(modelData.ssid, "")
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

