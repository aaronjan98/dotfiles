import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../services" as Sv

// Clipboard history popup, modeled on WifiPopup/BluetoothPopup: a native
// quickshell PanelWindow + scrim, instead of an external fuzzel dmenu.
// That earlier fuzzel-based approach relied on Hyprland's keyboard-focus-loss
// signal to close on click-outside, which never fires for clicks on
// non-focusable targets (the bar itself, empty desktop) -- a native popup
// sidesteps that entirely: the scrim's MouseArea only fires on an actual click.
//
// Open/entries state lives in the ClipboardCtl singleton (not here), since
// Super+Ctrl+V drives it via `qs ipc call clipboard toggle` -- there's no
// per-TopBar-instance keybind to hang that on, and every monitor's copy of
// this popup needs to agree on whether it's open (same pattern as Notifs'
// centerOpen singleton + NotifLayer, instantiated once per screen).
Item {
  id: api

  required property QtObject parentWindow   // TopBar PanelWindow

  // -------------------------------------------------
  // SCRIM (fullscreen) -- BEHIND popup, click-outside closes
  // -------------------------------------------------
  PanelWindow {
    id: scrim
    screen: api.parentWindow.screen
    visible: Sv.ClipboardCtl.open

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
      focus: Sv.ClipboardCtl.open
      Keys.onEscapePressed: Sv.ClipboardCtl.hide()

      MouseArea {
        anchors.fill: parent
        onClicked: Sv.ClipboardCtl.hide()
      }
    }
  }

  // -------------------------------------------------
  // POPUP as PanelWindow -- ABOVE scrim, takes keyboard
  // -------------------------------------------------
  PanelWindow {
    id: pop
    screen: api.parentWindow.screen
    visible: Sv.ClipboardCtl.open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: Sv.ClipboardCtl.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    anchors.top: true
    anchors.left: true

    margins.top: C.Appearance.topH + 10
    margins.left: Math.max(0, api.parentWindow.screen.width - implicitWidth - 10)

    color: "transparent"

    implicitWidth: 380
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

      opacity: Sv.ClipboardCtl.open ? 1 : 0
      scale: Sv.ClipboardCtl.open ? 1 : 0.92
      Behavior on opacity { NumberAnimation { duration: 140 } }
      Behavior on scale { NumberAnimation { duration: 140 } }

      MouseArea {
        anchors.fill: parent
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Item {
        id: focusRoot
        anchors.fill: parent
        focus: Sv.ClipboardCtl.open

        Keys.onEscapePressed: Sv.ClipboardCtl.hide()

        ColumnLayout {
          id: content
          anchors.fill: parent
          anchors.margins: 12
          spacing: 10

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text { text: "Clipboard History"; color: "white"; font.pixelSize: 14; font.weight: 600 }
            Item { Layout.fillWidth: true }
            Text {
              text: Sv.ClipboardCtl.entries.length + (Sv.ClipboardCtl.entries.length === 1 ? " item" : " items")
              color: Qt.rgba(1,1,1,0.75)
              font.pixelSize: 12
            }
          }

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

              Text { anchors.centerIn: parent; text: "Refresh"; color: "white"; font.pixelSize: 12 }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Sv.ClipboardCtl.refresh()
              }
            }

            Rectangle {
              Layout.preferredWidth: 70
              Layout.preferredHeight: 28
              radius: 10
              color: Qt.rgba(1,1,1,0.12)
              border.width: 1
              border.color: Qt.rgba(1,1,1,0.15)

              Text { anchors.centerIn: parent; text: "Close"; color: "white"; font.pixelSize: 12 }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Sv.ClipboardCtl.hide()
              }
            }
          }

          Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 360
            clip: true

            contentWidth: width
            contentHeight: listCol.implicitHeight

            ColumnLayout {
              id: listCol
              width: parent.width
              spacing: 6

              Text {
                Layout.fillWidth: true
                visible: Sv.ClipboardCtl.entries.length === 0
                text: "No clipboard history."
                color: Qt.rgba(1,1,1,0.7)
                font.pixelSize: 12
              }

              Repeater {
                model: Sv.ClipboardCtl.entries

                Rectangle {
                  id: row
                  required property var modelData
                  Layout.fillWidth: true
                  Layout.preferredHeight: 34
                  radius: 10
                  color: rowArea.containsMouse ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.10)
                  border.width: 1
                  border.color: rowArea.containsMouse ? Qt.rgba(1,1,1,0.32) : Qt.rgba(1,1,1,0.15)
                  antialiasing: true

                  Behavior on color { ColorAnimation { duration: 80 } }
                  Behavior on border.color { ColorAnimation { duration: 80 } }

                  Text {
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: Text.AlignVCenter
                    text: Sv.ClipboardCtl.entryPreview(row.modelData)
                    color: "white"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }

                  MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Sv.ClipboardCtl.selectEntry(row.modelData)
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
