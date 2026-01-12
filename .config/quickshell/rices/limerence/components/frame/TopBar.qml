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

  // Hyprland workspace model (ObjectModel)
  readonly property var wsModel: Hyprland.workspaces
  readonly property var wsList: wsModel ? wsModel.values : []

  // Active workspace math (domain/slot)
  readonly property int wsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
  readonly property int domain: (wsId <= 9) ? 1 : Math.floor(wsId / 10)
  readonly property int slot: (wsId <= 9) ? wsId : (wsId % 10)

  function workspaceIdFor(dom, slot) {
    return (dom === 1) ? slot : (dom * 10 + slot)
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

  // Show 4 minimum; expand to include current slot and any slot that has windows; cap at 9.
  function slotCountToShow() {
    var m = 4
    m = Math.max(m, root.slot)
    m = Math.max(m, maxSlotWithWindowsInDomain(root.domain))
    return Math.min(9, m)
  }

  Item {
    anchors.fill: parent

    // ONE bubble for the entire slot cluster
    W.BubbleItem {
      id: slotBubble
      anchors.centerIn: parent

      // extra tight padding for a cluster bubble
      // (keeps your global token but makes the cluster look snug)
      // If you want it tighter still, drop dotCell and spacing a bit.
      Row {
        id: slotRow
        spacing: 4

        Repeater {
          model: root.slotCountToShow()

          delegate: Item {
            // Clickable "cell" per dot inside the shared bubble
            // Keeping this slightly larger makes clicking easier.
            readonly property int slotN: modelData + 1
            readonly property int targetWs: root.workspaceIdFor(root.domain, slotN)
            readonly property bool occ: root.toplevelCountForWorkspaceId(targetWs) > 0

            width: 14
            height: 14

            W.WorkspaceDot {
              anchors.centerIn: parent
              dotSize: 7
              active: (root.slot === slotN)
              occupied: occ
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                // Keep UI and scripts aligned:
                S.DomainMemory.setLastSlot(root.domain, slotN)
                S.DomainMemory.ensureVisited(root.domain)

                Hyprland.dispatch("workspace " + targetWs)
              }
            }
          }
        }
      }
    }
  }
}

