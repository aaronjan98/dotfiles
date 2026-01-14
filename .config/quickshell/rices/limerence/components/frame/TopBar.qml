import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../widgets" as W
import "../state" as S
import "../services" as Sv

PanelWindow {
  id: root
  required property ShellScreen screen
  screen: screen

  exclusionMode: ExclusionMode.Auto
  anchors.top: true
  anchors.left: true
  anchors.right: true

  margins.left: C.Appearance.leftW
  implicitHeight: C.Appearance.topH
  color: "transparent"

  readonly property var wsModel: Hyprland.workspaces
  readonly property var wsList: wsModel ? wsModel.values : []

  readonly property int wsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
  readonly property int domain: (wsId <= 9) ? 1 : Math.floor(wsId / 10)
  readonly property int slot: (wsId <= 9) ? wsId : (wsId % 10)

  property int displaySlots: 4
  property int targetSlots: 4

  property bool showSideIslands: true

  property bool wifiPopupOpen: false

  Timer {
    id: slotsPollTimer
    interval: 500
    repeat: true
    running: true
    onTriggered: root.updateSlotsUI()
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
    displaySlots = slotCountToShow()
    targetSlots = displaySlots
  }

  function workspaceIdFor(dom, slotN) { return (dom === 1) ? slotN : (dom * 10 + slotN) }

  function toplevelCountForWorkspaceId(id) {
    for (var i = 0; i < wsList.length; i++) {
      var w = wsList[i]
      if (!w) continue
      if (w.id === id) {
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

      var id = w.id
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

  // ---- NEW: system stats provider (no visuals) ----
  W.SystemStats {
    id: stats
  }

  Item {
    anchors.fill: parent

    // ---- LEFT: CPU + Mem ----
    W.Pill {
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      anchors.leftMargin: 6
    
      useBackground: root.showSideIslands
    
      Row {
        spacing: 8
    
        Text {
          text: "CPU " + stats.cpuUsage + "%"
          color: "white"
          font.pixelSize: C.Appearance.pillFont
        }
    
        Rectangle {
          width: 1
          height: 12
          color: Qt.rgba(1, 1, 1, 0.18)
        }
    
        Text {
          text: "MEM " + stats.memUsage + "%"
          color: "white"
          font.pixelSize: C.Appearance.pillFont
        }
      }
    }

    // ---- CENTER: your existing workspace island ----
    W.BubbleItem {
      anchors.centerIn: parent

      W.DotTrack {
        axis: "h"
        count: root.displaySlots
        activeIndex: root.slot - 1
        dotSize: 7
        pillFactor: 2.1
        gap: 4
        animMs: 140

        occupiedFn: function(i) {
          var slotN = i + 1
          var ws = root.workspaceIdFor(root.domain, slotN)
          return root.toplevelCountForWorkspaceId(ws) > 0
        }

        onClicked: function(i) {
          var slotN = i + 1
          var targetWs = root.workspaceIdFor(root.domain, slotN)

          S.DomainMemory.setLastSlot(root.domain, slotN)
          S.DomainMemory.ensureVisited(root.domain)
          Hyprland.dispatch("workspace " + targetWs)
        }
      }
    }

    // ---- RIGHT: wifi + clock ----
    W.Pill {
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      anchors.rightMargin: 6
    
      useBackground: root.showSideIslands
    
      Row {
        spacing: 8
    
        W.WifiIcon {
          onClicked: root.wifiPopupOpen = !root.wifiPopupOpen
        }
    
        Rectangle { width: 1; height: 12; color: Qt.rgba(1,1,1,0.18) }
    
        W.Clock {
          color: "white"
          font.pixelSize: C.Appearance.pillFont
          format: "ddd, MMM dd HH:mm:ss"
        }
      }
    }
  }

  W.WifiPopup {
    screen: root.screen
    open: root.wifiPopupOpen
  }
}

