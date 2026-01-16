import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../services" 1.0 as Sv

Item {
  id: api

  required property QtObject parentWindow
  property bool open: false
  signal dismissed()

  function requestClose() { dismissed() }

  // ===========================
  // SCRIM (click-outside + Esc)
  // ===========================
  PanelWindow {
    id: scrim
    screen: api.parentWindow.screen
    visible: api.open

    // PanelWindow cannot do anchors.fill
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

  // ===========================
  // POPUP
  // ===========================
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
    implicitWidth: 360
    implicitHeight: panel.implicitHeight

    onVisibleChanged: if (visible) focusRoot.forceActiveFocus()

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

      // Eat clicks so the scrim doesn't close us
      MouseArea {
        anchors.fill: parent
        onClicked: (mouse) => { mouse.accepted = true }
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
          spacing: 12

          // ===== Header =====
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: "Brightness"
              color: "white"
              font.pixelSize: 14
              font.weight: 600
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              Layout.preferredWidth: 80
              Layout.preferredHeight: 26
              radius: 10
              color: Qt.rgba(1,1,1,0.12)
              border.width: 1
              border.color: Qt.rgba(1,1,1,0.15)

              Text {
                anchors.centerIn: parent
                text: "Close"
                color: "white"
                font.pixelSize: 12
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: api.requestClose()
              }
            }
          }

          // ===== Screen brightness =====
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              Text { text: "Screen"; color: Qt.rgba(1,1,1,0.9); font.pixelSize: 12 }
              Item { Layout.fillWidth: true }
              Text { text: Sv.BrightnessCtl.screenPercent + "%"; color: Qt.rgba(1,1,1,0.8); font.pixelSize: 12 }
            }

            SliderRow {
              Layout.fillWidth: true
              value: Sv.BrightnessCtl.screenPercent
              enabled: Sv.BrightnessCtl.ok && Sv.BrightnessCtl.screenDev.length > 0
              onValueChangedLive: (v) => Sv.BrightnessCtl.setScreenPercent(v)
            }
          }

          // ===== Keyboard brightness =====
          ColumnLayout {
            visible: Sv.BrightnessCtl.hasKbd
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              Text { text: "Keyboard"; color: Qt.rgba(1,1,1,0.9); font.pixelSize: 12 }
              Item { Layout.fillWidth: true }
              Text { text: Sv.BrightnessCtl.kbdPercent + "%"; color: Qt.rgba(1,1,1,0.8); font.pixelSize: 12 }
            }

            SliderRow {
              Layout.fillWidth: true
              value: Sv.BrightnessCtl.kbdPercent
              enabled: Sv.BrightnessCtl.hasKbd
              onValueChangedLive: (v) => Sv.BrightnessCtl.setKbdPercent(v)
            }
          }

          // ===== Night light =====
          Text {
            Layout.fillWidth: true
            text: "Night light"
            color: Qt.rgba(1,1,1,0.9)
            font.pixelSize: 12
            font.weight: 600
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: Sv.GammaCtl.enabled ? "On" : "Off"
              color: Qt.rgba(1,1,1,0.75)
              font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            Rectangle {
              width: 44; height: 22; radius: 999
              color: Sv.GammaCtl.enabled ? Qt.rgba(1,1,1,0.18) : Qt.rgba(1,1,1,0.08)
              border.width: 1; border.color: Qt.rgba(1,1,1,0.18)

              Rectangle {
                width: 18; height: 18; radius: 999
                y: 2
                x: Sv.GammaCtl.enabled ? (parent.width - width - 2) : 2
                color: "white"
                Behavior on x { NumberAnimation { duration: 120 } }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Sv.GammaCtl.setEnabled(!Sv.GammaCtl.enabled)
              }
            }
          }

          // Slider:
          //  - preview() updates UI only
          //  - commit() applies once on release (no flashing)
          SliderRow {
            Layout.fillWidth: true
            enabled: Sv.GammaCtl.enabled
            value: Sv.GammaCtl.tempPercent
            onValueChangedLive: (v) => Sv.GammaCtl.preview(v)
            onValueCommitted: (_v) => Sv.GammaCtl.commit()
          }

          Text {
            Layout.fillWidth: true
            text: Sv.GammaCtl.enabled
              ? ("Temperature: " + Sv.GammaCtl.percentToKelvin(Sv.GammaCtl.tempPercent) + "K")
              : "Temperature: default"
            color: Qt.rgba(1,1,1,0.75)
            font.pixelSize: 11
          }
        }
      }
    }
  }

  // ==================================================
  // SliderRow
  // - Emits valueChangedLive while dragging
  // - Emits valueCommitted once on release
  // ==================================================
  component SliderRow: Item {
    id: s
    property int value: 0
    property bool enabled: true

    signal valueChangedLive(int v)
    signal valueCommitted(int v)

    implicitHeight: 22

    function clamp(v) { return Math.max(0, Math.min(100, Math.round(v))) }

    Rectangle {
      id: track
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      height: 8
      radius: 999
      color: Qt.rgba(1,1,1,0.14)
      border.width: 1
      border.color: Qt.rgba(1,1,1,0.12)
      opacity: s.enabled ? 1 : 0.45
    }

    Rectangle {
      id: fill
      anchors.left: track.left
      anchors.verticalCenter: track.verticalCenter
      height: track.height
      radius: track.radius
      width: track.width * (s.value / 100.0)
      color: Qt.rgba(1,1,1,0.28)
      opacity: s.enabled ? 1 : 0.45
    }

    Rectangle {
      id: knob
      width: 18
      height: 18
      radius: 999
      color: "white"
      opacity: s.enabled ? 1 : 0.6
      y: (parent.height - height) / 2
      x: Math.max(0, Math.min(track.width - width, fill.width - width/2))
    }

    MouseArea {
      anchors.fill: parent
      enabled: s.enabled
      cursorShape: Qt.PointingHandCursor

      function setFromMouse(mx) {
        const local = Math.max(0, Math.min(track.width, mx))
        const v = s.clamp((local / track.width) * 100)
        s.value = v
        s.valueChangedLive(v)
      }

      onPressed: (mouse) => setFromMouse(mouse.x)
      onPositionChanged: (mouse) => { if (pressed) setFromMouse(mouse.x) }
      onReleased: s.valueCommitted(s.value)
    }
  }
}

