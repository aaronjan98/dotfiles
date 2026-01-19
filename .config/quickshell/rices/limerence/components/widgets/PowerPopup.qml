import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "../../config" as C

PanelWindow {
  id: win
  required property ShellScreen screen
  screen: screen

  property bool open: false
  signal dismissed()

  visible: open
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true

  Process {
    id: proc
    stdout: SplitParser { onRead: s => console.log("[power stdout]", s) }
    stderr: SplitParser { onRead: s => console.warn("[power stderr]", s) }
  }

  function run(cmd) {
    proc.running = false
    proc.command = ["sh", "-lc", cmd]
    proc.running = true
  }

  function requestClose() { win.dismissed() }

  Item {
    id: root
    anchors.fill: parent
    focus: true

    onVisibleChanged: if (visible) Qt.callLater(function() { root.forceActiveFocus() })
    Keys.onEscapePressed: requestClose()

    Item {
      id: bubbleBox
      width: 236
      height: col.implicitHeight + C.Appearance.popupPad * 2
    
      anchors.left: parent.left
      anchors.bottom: parent.bottom
    
      // Keep it inside the Hyprland content region:
      anchors.leftMargin: C.Appearance.leftW + 10
      anchors.bottomMargin: C.Appearance.framePadBottom + 8
    }

    // click-outside close (4 regions)
    MouseArea { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: bubbleBox.top; onClicked: requestClose() }
    MouseArea { anchors.top: bubbleBox.top; anchors.left: parent.left; anchors.right: bubbleBox.left; anchors.bottom: parent.bottom; onClicked: requestClose() }
    MouseArea { anchors.top: bubbleBox.top; anchors.left: bubbleBox.right; anchors.right: parent.right; anchors.bottom: parent.bottom; onClicked: requestClose() }
    MouseArea { anchors.top: bubbleBox.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; onClicked: requestClose() }

    Rectangle {
      id: bubble
      x: bubbleBox.x
      y: bubbleBox.y
      width: bubbleBox.width
      height: col.implicitHeight + C.Appearance.popupPad * 2

      radius: C.Appearance.bubbleRadius
      antialiasing: true
      clip: true

      // Less transparent (match WiFi popup readability)
      color: C.Appearance.popupBg

      // Dark glaze
      Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(0, 0, 0, C.Appearance.popupOverlayA)
        antialiasing: true
      }

      border.width: C.Appearance.border
      border.color: C.Appearance.borderCol

      ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: C.Appearance.popupPad
        spacing: C.Appearance.popupRowGap

        Text {
          text: "Power"
          color: "white"
          opacity: 0.92
          font.pixelSize: 13
          horizontalAlignment: Text.AlignHCenter
          Layout.fillWidth: true
        }

        PowerRow {
          label: "Lock"
          icon: ""
          onTriggered: { run("hyprlock || swaylock -f || gtklock || loginctl lock-session || true"); requestClose() }
        }

        PowerRow {
          label: "Screen off"
          icon: "󰶐"
          onTriggered: { run("nohup hyprlock >/dev/null 2>&1 & sleep 0.2; /run/current-system/sw/bin/screen-blackout-on || true"); requestClose() }
        }

        PowerRow {
          label: "Sleep"
          icon: ""
          onTriggered: { run("systemctl suspend || busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager Suspend b true || true"); requestClose() }
        }

        PowerRow {
          label: "Restart"
          icon: ""
          onTriggered: { run("systemctl reboot || busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager Reboot b true || true"); requestClose() }
        }

        PowerRow {
          label: "Power off"
          icon: "⏻"
          onTriggered: { run("systemctl poweroff || busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager PowerOff b true || true"); requestClose() }
        }

        PowerRow {
          label: "Logout"
          icon: "󰍃"
          onTriggered: { run("hyprctl dispatch exit || loginctl terminate-user $USER || true"); requestClose() }
        }
      }
    }
  }

  component PowerRow: Item {
    id: row
    property string label: ""
    property string icon: ""
    signal triggered()
  
    implicitHeight: 34
    Layout.fillWidth: true
  
    // Match WiFi-ish row sizing
    readonly property int pad: 8
    readonly property int iconColW: 26   // fixed icon column => perfect vertical alignment
    readonly property int gap: 10
  
    // Full-width hit area (easy clicks)
    TapHandler {
      acceptedButtons: Qt.LeftButton
      onTapped: row.triggered()
    }
  
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.NoButton
    }
  
    // The visible row "pill" spans the full available width
    Rectangle {
      anchors.fill: parent
      radius: Math.max(10, C.Appearance.bubbleRadius - 7)
      color: Qt.rgba(1, 1, 1, 0.08)
      antialiasing: true
  
      // Optional subtle border, similar to WiFi row feel
      border.width: 1
      border.color: Qt.rgba(1, 1, 1, 0.10)
  
      RowLayout {
        anchors.fill: parent
        anchors.margins: pad
        spacing: gap
  
        // Fixed-width icon column (all icons align to the same x)
        Item {
          Layout.preferredWidth: iconColW
          Layout.fillHeight: true
  
          Text {
            anchors.centerIn: parent
            text: row.icon
            font.family: C.Appearance.iconFont
            font.pixelSize: 15
            color: "white"
            opacity: 0.95
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }
  
        // Centered label column: takes remaining space and centers the text
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
  
          Text {
            anchors.centerIn: parent
            text: row.label
            color: "white"
            opacity: 0.95
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
          }
        }
  
        // Optional right spacer column to keep the *label visually centered*,
        // since the icon column consumes space on the left.
        // Make this the same width as iconColW so the label is truly centered.
        Item {
          Layout.preferredWidth: iconColW
          Layout.fillHeight: true
        }
      }
    }
  }
}

