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
  anchors.left: true
  anchors.top: true
  anchors.bottom: true

  margins.top: C.Appearance.topH
  implicitWidth: C.Appearance.leftW
  color: "transparent"

  readonly property var wsModel: Hyprland.workspaces
  readonly property var wsList: wsModel ? wsModel.values : []

  readonly property int wsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
  readonly property int domain: (wsId <= 9) ? 1 : Math.floor(wsId / 10)

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

  // Show 3 minimum; expand to include current domain and any domain with windows; fill gaps 1..max
  function domainCountToShow() {
    var m = 3
    m = Math.max(m, root.domain)
    m = Math.max(m, maxDomainWithWindows())
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

    // ONE bubble for the entire domain cluster
    W.BubbleItem {
      id: domainBubble
      anchors.verticalCenter: parent.verticalCenter
      anchors.horizontalCenter: parent.horizontalCenter

      Column {
        spacing: 6

        Repeater {
          model: root.domainCountToShow()

          delegate: Item {
            readonly property int domN: modelData + 1
            readonly property bool occ: root.domainOccupied(domN)

            width: 14
            height: 14

            W.WorkspaceDot {
              anchors.centerIn: parent
              dotSize: 7
              active: (root.domain === domN)
              occupied: occ
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                // Ensure this domain is considered "visited" for scripts/UI
                S.DomainMemory.ensureVisited(domN)

                // Jump to the last slot used in that domain
                const s = S.DomainMemory.lastSlot(domN)
                const target = (domN === 1) ? s : (domN * 10 + s)

                Hyprland.dispatch("workspace " + target)
              }
            }
          }
        }
      }
    }
  }
}

