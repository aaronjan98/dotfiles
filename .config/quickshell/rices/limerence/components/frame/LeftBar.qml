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

  // --- UI count latch (expand immediately, shrink later) ---
  property int displayDomains: 3
  property int targetDomains: 3

  Timer {
    id: shrinkDomainsTimer
    interval: 350
    repeat: false
    onTriggered: root.displayDomains = root.targetDomains
  }

  Timer {
    id: domainsPollTimer
    interval: 500
    repeat: true
    running: true
    onTriggered: root.updateDomainsUI()
  }

  function updateDomainsUI() {
    const t = domainCountToShow()
    targetDomains = t

    if (t > displayDomains) {
      displayDomains = t
      shrinkDomainsTimer.stop()
    } else if (t < displayDomains) {
      shrinkDomainsTimer.restart()
    }
  }

  property int lastDomainSeen: domain
  onDomainChanged: {
    S.NavState.prevDomain = lastDomainSeen
    lastDomainSeen = domain
    updateDomainsUI()
  }

  Component.onCompleted: {
    displayDomains = domainCountToShow()
    targetDomains = displayDomains
  }

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

    W.BubbleItem {
      anchors.verticalCenter: parent.verticalCenter
      anchors.horizontalCenter: parent.horizontalCenter

      W.DotTrack {
        axis: "v"
        count: root.displayDomains
        activeIndex: root.domain - 1
        dotSize: 7
        pillFactor: 2.1
        gap: 6
        animMs: 140

        occupiedFn: function(i) {
          var domN = i + 1
          return root.domainOccupied(domN)
        }

        onClicked: function(i) {
          var domN = i + 1
          S.DomainMemory.ensureVisited(domN)

          var s = S.DomainMemory.lastSlot(domN)
          var target = (domN === 1) ? s : (domN * 10 + s)
          Hyprland.dispatch("workspace " + target)
        }
      }
    }
  }
}

