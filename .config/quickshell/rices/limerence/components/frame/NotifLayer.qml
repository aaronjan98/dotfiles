// components/frame/NotifLayer.qml
import Quickshell
import Quickshell.Wayland
import QtQuick

import "../../config" as C
import "../services" as Sv
import "../widgets" as W

Item {
  id: api
  required property ShellScreen screen

  // optional: turn on debug here
  // Component.onCompleted: Sv.Notifs.debug = true

  // ---------- Toast window ----------
  PanelWindow {
    id: toastWin
    screen: api.screen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors.top: true
    anchors.right: true

    visible: Sv.Notifs.popups.count > 0
    color: "transparent"

    implicitWidth: 360
    implicitHeight: Math.min(screen.height, 420)

    Column {
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: C.Appearance.topH + 10
      anchors.rightMargin: 10
      spacing: 8

      Repeater {
        model: Sv.Notifs.popups

        delegate: Item {
          width: toastWin.implicitWidth - 20
          height: toast.implicitHeight

          // animate only on creation
          property bool entered: false
          x: entered ? 0 : (width + 30)
          Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          Component.onCompleted: entered = true

          W.NotificationToast {
            id: toast
            width: parent.width

            nid_: nid
            appName_: appName
            summary_: summary
            body_: body

            iconName_: (iconName !== undefined && iconName !== null) ? iconName : ""
            desktopEntry_: (desktopEntry !== undefined && desktopEntry !== null) ? desktopEntry : ""
            imagePath_: (imagePath !== undefined && imagePath !== null) ? imagePath : ""

            actionsNorm_: (actionsNorm !== undefined && actionsNorm !== null) ? actionsNorm : []
            actions_: (actions !== undefined && actions !== null) ? actions : []
            defaultKey_: (defaultKey !== undefined && defaultKey !== null) ? defaultKey : ""
          }
        }
      }
    }
  }

  // ---------- Scrim (click-out closes) ----------
  PanelWindow {
    id: scrimWin
    screen: api.screen

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    margins.top: C.Appearance.topH
    margins.left: C.Appearance.leftW
    margins.right: C.Appearance.framePadRight
    margins.bottom: C.Appearance.framePadBottom

    color: "transparent"
    visible: centerWin.shown

    MouseArea {
      anchors.fill: parent
      onClicked: Sv.Notifs.closeCenter()
    }
  }

  // ---------- Center window (slides surface via margins.right) ----------
  PanelWindow {
    id: centerWin
    screen: api.screen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    margins.top: C.Appearance.topH + 6
    margins.bottom: C.Appearance.framePadBottom + 6

    property int baseRight: C.Appearance.framePadRight + 6
    property int closedRight: baseRight - implicitWidth - 20

    margins.right: closedRight

    color: "transparent"
    implicitWidth: 380

    property bool shown: false
    visible: shown

    NumberAnimation {
      id: slideAnim
      target: centerWin
      property: "margins.right"
      duration: 180
      easing.type: Easing.OutCubic
    }

    Timer {
      id: hideTimer
      interval: 220
      repeat: false
      onTriggered: centerWin.shown = false
    }

    W.NotificationCenter {
      anchors.fill: parent
    }

    function animateOpen() {
      hideTimer.stop()
      centerWin.shown = true
      centerWin.margins.right = centerWin.closedRight
      Qt.callLater(() => {
        slideAnim.from = centerWin.closedRight
        slideAnim.to = centerWin.baseRight
        slideAnim.start()
      })
    }

    function animateClose() {
      slideAnim.from = centerWin.margins.right
      slideAnim.to = centerWin.closedRight
      slideAnim.start()
      hideTimer.restart()
    }

    Connections {
      target: Sv.Notifs
      function onCenterOpenChanged() {
        if (Sv.Notifs.centerOpen) centerWin.animateOpen()
        else centerWin.animateClose()
      }
    }

    Component.onCompleted: {
      if (Sv.Notifs.centerOpen) {
        centerWin.shown = true
        centerWin.margins.right = centerWin.baseRight
      } else {
        centerWin.shown = false
        centerWin.margins.right = centerWin.closedRight
      }
    }
  }
}

