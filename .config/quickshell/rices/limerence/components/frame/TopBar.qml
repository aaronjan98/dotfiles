import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "../../config" as C
import "../widgets" as W

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

  // Bubble size that fits in the top bar lane
  readonly property int bubbleSize: Math.min(C.Appearance.topH, C.Appearance.leftW) - 2

  // Hyprland workspace model (ObjectModel)
  readonly property var wsModel: Hyprland.workspaces
  // Safer JS-iterable list (QList<QObject*> exposed by Quickshell ObjectModel)
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
        // HyprlandWorkspace.toplevels is an ObjectModel (windows on that workspace)
        // Use .count if present; otherwise fall back to .values.length.
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
        if (id >= 1 && id <= 9) m = Math.max(m, id) // slot == id
      } else {
        var lo = dom * 10 + 1
        var hi = dom * 10 + 9
        if (id >= lo && id <= hi) m = Math.max(m, id % 10)
      }
    }
    return m
  }

  // Show 4 minimum; expand to include current slot and any slot that has windows; cap at 9.
  // This is what keeps dots visible after you leave, as long as windows remain there.
  function slotCountToShow() {
    var m = 4
    m = Math.max(m, root.slot) // always show current slot while you're there
    m = Math.max(m, maxSlotWithWindowsInDomain(root.domain)) // keep extended slots if windows exist
    return Math.min(9, m)
  }

  Item {
    anchors.fill: parent

    Row {
      anchors.centerIn: parent
      spacing: 6

      Repeater {
        model: root.slotCountToShow()

        delegate: W.BubbleItem {
          bubbleSize: root.bubbleSize

          readonly property int slotN: modelData + 1
          readonly property int targetWs: root.workspaceIdFor(root.domain, slotN)
          readonly property bool occ: root.toplevelCountForWorkspaceId(targetWs) > 0

          W.WorkspaceDot {
            anchors.centerIn: parent
            dotSize: 7
            active: (root.slot === slotN)
            occupied: occ
          }

          onClicked: Hyprland.dispatch("workspace " + targetWs)
        }
      }
    }
  }
}

