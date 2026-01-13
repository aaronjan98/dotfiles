import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "../../config" as C
import "../widgets" as W
import "../state" as S

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

  // --- UI count latch (expand immediately, shrink later) ---
  property int displaySlots: 4
  property int targetSlots: 4

  // Poll because wsList changes don't reliably emit wsListChanged
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

  // Keep “seen” slot so scripts + UI can share direction/state if needed later.
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

  function workspaceIdFor(dom, slotN) {
    return (dom === 1) ? slotN : (dom * 10 + slotN)
  }

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

  Item {
    anchors.fill: parent

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
  }
}

