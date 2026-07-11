import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../widgets" as W
import "../state" as S

PanelWindow {
  id: root
  // screen is set by the caller (PanelWindow's own Quickshell property — not re-declared here,
  // since `required property ShellScreen screen` would shadow it and break multi-monitor routing)

  property bool isExternal: false

  exclusionMode: ExclusionMode.Auto
  anchors.top: true
  anchors.left: true
  anchors.right: true

  // External: no LeftBar so no left margin.
  margins.left: isExternal ? 0 : C.Appearance.leftW
  implicitHeight: C.Appearance.topH
  color: "transparent"

  readonly property var wsModel: Hyprland.workspaces
  readonly property var wsList: wsModel ? wsModel.values : []

  property int wsId: 1
  readonly property int domain: (wsId <= 9) ? 1 : Math.floor(wsId / 10)
  readonly property int slot: (wsId <= 9) ? wsId : (wsId % 10)

  property int displaySlots: 4
  property int targetSlots: 4

  property bool showSideIslands: true
  property bool wifiPopupOpen: false
  property bool btPopupOpen: false
  property bool brightPopupOpen: false

  function workspaceBelongsToScreen(actualId) {
    return C.Layout.isExternal(root.screen)
      ? actualId >= 101 && actualId <= 109
      : actualId > 0 && actualId < 100
  }

  function logicalWorkspaceId(actualId) {
    return actualId
  }

  function actualWorkspaceId(logicalId) {
    return logicalId
  }

  Timer {
    id: slotsPollTimer
    interval: 250
    repeat: true
    running: true
    onTriggered: {
      root.updateScreenWorkspace()
      root.updateSlotsUI()
    }
  }

  function updateScreenWorkspace() {
    var nextId = 1
    if (Hyprland.monitors && Hyprland.monitors.values) {
      for (var m of Hyprland.monitors.values) {
        if (m && root.screen && m.name === root.screen.name && m.activeWorkspace) {
          nextId = root.logicalWorkspaceId(m.activeWorkspace.id)
          break
        }
      }
    } else if (Hyprland.focusedWorkspace) {
      nextId = root.logicalWorkspaceId(Hyprland.focusedWorkspace.id)
    }
    if (root.wsId !== nextId) root.wsId = nextId
  }

  function updateSlotsUI() {
    const t = slotCountToShow()
    targetSlots = t
    displaySlots = t
  }

  property int lastSlotSeen: slot
  onSlotChanged: {
    S.NavState.prevSlot = lastSlotSeen
    lastSlotSeen = slot
    updateSlotsUI()
  }

  Component.onCompleted: {
    updateScreenWorkspace()
    displaySlots = slotCountToShow()
    targetSlots = displaySlots
  }

  function workspaceIdFor(dom, slotN) {
    if (C.Layout.isExternal(root.screen)) return 100 + slotN
    return (dom === 1) ? slotN : (dom * 10 + slotN)
  }
  function actualWorkspaceIdFor(dom, slotN) { return actualWorkspaceId(workspaceIdFor(dom, slotN)) }

  function dispatchWorkspaceOnScreen(targetWs) {
    if (root.screen && root.screen.name) Hyprland.dispatch("focusmonitor " + root.screen.name)
    Hyprland.dispatch("workspace " + targetWs)
  }

  function toplevelCountForWorkspaceId(id) {
    var actualId = root.actualWorkspaceId(id)
    for (var i = 0; i < wsList.length; i++) {
      var w = wsList[i]
      if (!w) continue
      if (w.id === actualId) {
        if (w.toplevels && w.toplevels.count !== undefined) return w.toplevels.count
        if (w.toplevels && w.toplevels.values !== undefined) return w.toplevels.values.length
        return 0
      }
    }
    return 0
  }

  function maxSlotWithWindowsInDomain(dom) {
    var m = 0
    for (var i = 0; i < wsList.length; i++) {
      var w = wsList[i]
      if (!w) continue

      if (!root.workspaceBelongsToScreen(w.id)) continue
      var id = root.logicalWorkspaceId(w.id)
      var count = 0
      if (w.toplevels && w.toplevels.count !== undefined) count = w.toplevels.count
      else if (w.toplevels && w.toplevels.values !== undefined) count = w.toplevels.values.length
      if (count <= 0) continue

      if (dom === 1) {
        if (id >= 1 && id <= 9) m = Math.max(m, id)
      } else {
        var lo = dom * 10 + 1
        var hi = dom * 10 + 9
        if (id >= lo && id <= hi) m = Math.max(m, id % 10)
      }
    }
    return m
  }

  function slotCountToShow() {
    var m = 4
    m = Math.max(m, root.slot)
    m = Math.max(m, maxSlotWithWindowsInDomain(root.domain))
    return Math.min(9, m)
  }

  // ---- system stats provider ----
  W.SystemStats { id: stats }

  Item {
    anchors.fill: parent

    // Popup windows (positioned relative to THIS PanelWindow)
    W.WifiPopup {
      parentWindow: root
      open: root.wifiPopupOpen
      onDismissed: root.wifiPopupOpen = false
    }

    W.BluetoothPopup {
      parentWindow: root
      open: root.btPopupOpen
      onDismissed: root.btPopupOpen = false
    }

    W.BrightnessPopup {
      parentWindow: root
      open: root.brightPopupOpen
      onDismissed: root.brightPopupOpen = false
    }

    // ---- LEFT: CPU + Mem ----
    W.Pill {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: C.Appearance.m6
      useBackground: root.showSideIslands

      Row {
        spacing: C.Appearance.m8

        W.BatteryIcon { }

        Rectangle { width: C.Appearance.dividerW; height: C.Appearance.dividerH; color: Qt.rgba(1,1,1,0.18) }

        Text {
          text: "CPU " + stats.cpuUsage + "%"
          color: "white"
          font.pixelSize: C.Appearance.pillFont
        }

        Rectangle { width: C.Appearance.dividerW; height: C.Appearance.dividerH; color: Qt.rgba(1,1,1,0.18) }

        Text {
          text: "MEM " + stats.memUsage + "%"
          color: "white"
          font.pixelSize: C.Appearance.pillFont
        }
      }
    }

    // ---- CENTER: workspace island ----
    W.BubbleItem {
      anchors.centerIn: parent

      W.DotTrack {
        axis: "h"
        count: root.displaySlots
        activeIndex: root.slot - 1

        // Use DotTrack defaults (scaled): dotSize/gap/pillFactor/animMs

        occupiedFn: function(i) {
          var slotN = i + 1
          var ws = root.workspaceIdFor(root.domain, slotN)
          return root.toplevelCountForWorkspaceId(ws) > 0
        }

        onClicked: function(i) {
          var slotN = i + 1
          var targetWs = root.actualWorkspaceIdFor(root.domain, slotN)

          S.DomainMemory.setLastSlot(root.domain, slotN)
          S.DomainMemory.ensureVisited(root.domain)
          root.dispatchWorkspaceOnScreen(targetWs)
        }
      }
    }

    // ---- RIGHT: wifi + clock ----
    W.Pill {
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      anchors.rightMargin: C.Appearance.m6
      useBackground: root.showSideIslands

      Row {
        spacing: C.Appearance.m8

        W.WifiIcon { onClicked: root.wifiPopupOpen = !root.wifiPopupOpen }

        Rectangle { width: C.Appearance.dividerW; height: C.Appearance.dividerH; color: Qt.rgba(1,1,1,0.18) }

        W.BluetoothIcon { onClicked: root.btPopupOpen = !root.btPopupOpen }

        Rectangle { width: C.Appearance.dividerW; height: C.Appearance.dividerH; color: Qt.rgba(1,1,1,0.18) }

        W.VolumeIcon { }

        Rectangle { width: C.Appearance.dividerW; height: C.Appearance.dividerH; color: Qt.rgba(1,1,1,0.18) }

        W.BrightnessIcon { onClicked: root.brightPopupOpen = !root.brightPopupOpen }

        Rectangle { width: C.Appearance.dividerW; height: C.Appearance.dividerH; color: Qt.rgba(1,1,1,0.18) }

        W.NotificationIcon { }

        Rectangle { width: C.Appearance.dividerW; height: C.Appearance.dividerH; color: Qt.rgba(1,1,1,0.18) }

        W.Clock {
          color: "white"
          font.pixelSize: C.Appearance.pillFont
          format: "ddd, MMM dd HH:mm:ss"
        }
      }
    }
  }
}
