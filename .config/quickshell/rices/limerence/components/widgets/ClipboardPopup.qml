import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../../config" as C

// Clipboard history popup, modeled on WifiPopup/BluetoothPopup: a native
// quickshell PanelWindow + scrim, instead of an external fuzzel dmenu.
// That earlier fuzzel-based approach (shot-menu's shot-region-save sibling)
// relied on Hyprland's keyboard-focus-loss signal to close on click-outside,
// which is indistinguishable from a hover under this host's focus settings
// -- a native popup sidesteps that entirely: the scrim's MouseArea only
// fires on an actual click.
Item {
  id: api

  required property QtObject parentWindow   // TopBar PanelWindow
  property bool open: false
  signal dismissed()

  property var entries: []   // each: raw "id\tpreview" line from `cliphist list`

  function requestClose() { dismissed() }

  function entryId(line) {
    const i = line.indexOf("\t")
    return i < 0 ? line : line.slice(0, i)
  }

  function entryPreview(line) {
    const i = line.indexOf("\t")
    return i < 0 ? line : line.slice(i + 1)
  }

  function refresh() {
    listProc.running = false
    listProc.running = true
  }

  function selectEntry(line) {
    copyProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", api.entryId(line)]
    copyProc.running = false
    copyProc.running = true
    api.requestClose()
  }

  Process {
    id: listProc
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: api.entries = text.split("\n").filter(l => l.length > 0)
    }
  }

  Process { id: copyProc }

  // -------------------------------------------------
  // SCRIM (fullscreen) -- BEHIND popup, click-outside closes
  // -------------------------------------------------
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

  // -------------------------------------------------
  // POPUP as PanelWindow -- ABOVE scrim, takes keyboard
  // -------------------------------------------------
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

    margins.top: C.Appearance.topH + 10
    margins.left: Math.max(0, api.parentWindow.screen.width - implicitWidth - 10)

    color: "transparent"

    implicitWidth: 380
    implicitHeight: panel.implicitHeight

    onVisibleChanged: {
      if (visible) {
        focusRoot.forceActiveFocus()
        api.refresh()
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

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text { text: "Clipboard History"; color: "white"; font.pixelSize: 14; font.weight: 600 }
            Item { Layout.fillWidth: true }
            Text {
              text: api.entries.length + (api.entries.length === 1 ? " item" : " items")
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
                onClicked: api.refresh()
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
                onClicked: api.requestClose()
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
                visible: api.entries.length === 0
                text: "No clipboard history."
                color: Qt.rgba(1,1,1,0.7)
                font.pixelSize: 12
              }

              Repeater {
                model: api.entries

                Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  Layout.preferredHeight: 34
                  radius: 10
                  color: Qt.rgba(1,1,1,0.10)
                  border.width: 1
                  border.color: Qt.rgba(1,1,1,0.15)

                  Text {
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: Text.AlignVCenter
                    text: api.entryPreview(modelData)
                    color: "white"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: api.selectEntry(modelData)
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
