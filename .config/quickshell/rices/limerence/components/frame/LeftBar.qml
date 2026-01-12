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
  anchors.left: true
  anchors.top: true
  anchors.bottom: true

  margins.top: C.Appearance.topH
  implicitWidth: C.Appearance.leftW
  color: "transparent"

  readonly property int bubbleSize: Math.min(C.Appearance.topH, C.Appearance.leftW) - 2

  readonly property var wsModel: Hyprland.workspaces
  readonly property var wsList: wsModel ? wsModel.values : []

  readonly property int wsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
  readonly property int domain: (wsId <= 9) ? 1 : Math.floor(wsId / 10)
  readonly property int slot: (wsId <= 9) ? wsId : (wsId % 10)

  function domainOfWorkspaceId(id) {
    return (id <= 9) ? 1 : Math.floor(id / 10)
  }

  function workspaceHasWindows(w) {
    if (!w || !w.toplevels) return false
    if (w.toplevels.count !== undefined) return w.toplevels.count > 0
    if (w.toplevels.values !== undefined) return w.toplevels.values.length > 0
    return false
  }

  function maxDomainWithWindows() {
    var m = 0
    for (var i = 0; i < wsList.length; i++) {
      var w = wsList[i]
      if (workspaceHasWindows(w)) m = Math.max(m, domainOfWorkspaceId(w.id))
    }
    return m
  }

  // Show 3 minimum; expand to include current domain and any domain with windows.
  // Fill gaps: show 1..max.
  function domainCountToShow() {
    var m = 3
    m = Math.max(m, root.domain)          // show where you are even if empty
    m = Math.max(m, maxDomainWithWindows()) // keep domains if windows exist
    return m
  }

  function domainOccupied(dom) {
    for (var i = 0; i < wsList.length; i++) {
      var w = wsList[i]
      if (workspaceHasWindows(w) && domainOfWorkspaceId(w.id) === dom) return true
    }
    return false
  }

  Item {
    anchors.fill: parent

    Column {
      anchors.verticalCenter: parent.verticalCenter
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8

      Repeater {
        model: root.domainCountToShow()

        delegate: W.BubbleItem {
          bubbleSize: root.bubbleSize

          readonly property int domN: modelData + 1
          readonly property bool occ: root.domainOccupied(domN)

          W.WorkspaceDot {
            anchors.centerIn: parent
            dotSize: 7
            active: (root.domain === domN)
            occupied: occ
          }

          onClicked: {
            const target = (domN === 1) ? 1 : (domN * 10 + 1)
            Hyprland.dispatch("workspace " + target)
          }
        }
      }
    }
  }
}

