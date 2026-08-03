import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "../../config" as C
import "../widgets" as W
import "../state" as S

PanelWindow {
  id: root
  // screen set by caller — not re-declared here to avoid shadowing PanelWindow.screen

  exclusionMode: ExclusionMode.Auto
  anchors.left: true
  anchors.top: true
  anchors.bottom: true

  margins.top: C.Appearance.topH
  implicitWidth: C.Appearance.leftW
  color: "transparent"

  readonly property var wsModel: Hyprland.workspaces
  readonly property var wsList: wsModel ? wsModel.values : []

  property int wsId: 1
  readonly property bool onExternalRow: wsId >= 101 && wsId <= 109
  readonly property int domain: onExternalRow ? 1 : ((wsId <= 9) ? 1 : Math.floor(wsId / 10))

  // --- UI count latch (expand immediately, shrink later) ---
  property int displayDomains: 3
  property int targetDomains: 3

  // Power popup state
  property bool powerOpen: false
  readonly property string externalOutput: "DP-1"

  function workspaceBelongsToScreen(actualId) {
    return actualId > 0 && actualId < 100
  }

  function logicalWorkspaceId(actualId) {
    return actualId
  }

  function actualWorkspaceId(logicalId) {
    return logicalId
  }

  function externalMonitor() {
    if (Hyprland.monitors && Hyprland.monitors.values) {
      for (var m of Hyprland.monitors.values) {
        if (m && m.name === root.externalOutput) return m
      }
    }
    return null
  }

  function externalActiveWorkspaceId() {
    var m = externalMonitor()
    if (m && m.activeWorkspace && m.activeWorkspace.id >= 101 && m.activeWorkspace.id <= 109) {
      return m.activeWorkspace.id
    }
    return 101
  }

  function externalFocused() {
    var m = externalMonitor()
    return !!(m && m.focused) || root.onExternalRow
  }

  function showExternalMarker() {
    return !!externalMonitor() || externalOccupied() || root.onExternalRow
  }

  function externalOccupied() {
    for (var i = 0; i < wsList.length; i++) {
      var w = wsList[i]
      if (!w) continue
      if (w.id >= 101 && w.id <= 109 && workspaceHasWindows(w)) return true
    }
    return false
  }

  function focusExternalRow() {
    var target = externalActiveWorkspaceId()
    if (externalMonitor()) Hyprland.dispatch("focusmonitor " + root.externalOutput)
    Hyprland.dispatch("workspace " + target)
  }

  Timer {
    id: shrinkDomainsTimer
    interval: 350
    repeat: false
    onTriggered: root.displayDomains = root.targetDomains
  }

  Timer {
    id: domainsPollTimer
    interval: 250
    repeat: true
    running: true
    onTriggered: {
      root.updateScreenWorkspace()
      root.updateDomainsUI()
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

  function updateDomainsUI() {
    const t = domainCountToShow()
    targetDomains = t

    if (t > displayDomains) {
      displayDomains = t
      shrinkDomainsTimer.stop()
    } else if (t < displayDomains) {
      // Debounce the shrink, but do NOT restart an already-running countdown:
      // the 250ms poll would otherwise keep resetting the 350ms timer before
      // it can ever elapse, so extra dots would never collapse.
      if (!shrinkDomainsTimer.running) shrinkDomainsTimer.start()
    } else {
      shrinkDomainsTimer.stop()
    }
  }

  property int lastDomainSeen: domain
  onDomainChanged: {
    S.NavState.prevDomain = lastDomainSeen
    lastDomainSeen = domain
    updateDomainsUI()
  }

  Component.onCompleted: {
    updateScreenWorkspace()
    displayDomains = domainCountToShow()
    targetDomains = displayDomains
  }

  function domainOfWorkspaceId(id) {
    return (id <= 9) ? 1 : Math.floor(id / 10)
  }

  function dispatchWorkspaceOnScreen(targetWs) {
    if (root.screen && root.screen.name) Hyprland.dispatch("focusmonitor " + root.screen.name)
    Hyprland.dispatch("workspace " + targetWs)
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
      if (!w) continue
      if (!root.workspaceBelongsToScreen(w.id)) continue
      var id = root.logicalWorkspaceId(w.id)
      if (workspaceHasWindows(w)) m = Math.max(m, domainOfWorkspaceId(id))
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
      if (!w) continue
      if (!root.workspaceBelongsToScreen(w.id)) continue
      var id = root.logicalWorkspaceId(w.id)
      if (workspaceHasWindows(w) && domainOfWorkspaceId(id) === dom) return true
    }
    return false
  }

  Item {
    anchors.fill: parent

    // ----- Center domain dots -----
    W.BubbleItem {
      anchors.verticalCenter: parent.verticalCenter
      anchors.horizontalCenter: parent.horizontalCenter

      Column {
        spacing: C.Appearance.dotGapV

        W.DotTrack {
          axis: "v"
          count: root.displayDomains
          activeIndex: root.domain - 1

          // Use DotTrack defaults (scaled): dotSize/gap/pillFactor/animMs

          occupiedFn: function(i) {
            var domN = i + 1
            return root.domainOccupied(domN)
          }

          onClicked: function(i) {
            var domN = i + 1
            S.DomainMemory.ensureVisited(domN)

            var s = S.DomainMemory.lastSlot(domN)
            var logicalTarget = (domN === 1) ? s : (domN * 10 + s)
            var target = root.actualWorkspaceId(logicalTarget)
            root.dispatchWorkspaceOnScreen(target)
          }
        }

        Rectangle {
          visible: root.showExternalMarker()
          width: C.Appearance.dotSize
          height: Math.max(1, C.Appearance.dividerW)
          radius: height / 2
          color: "white"
          opacity: 0.28
        }

        Item {
          visible: root.showExternalMarker()
          width: C.Appearance.dotSize
          height: root.externalFocused() ? Math.round(C.Appearance.dotSize * C.Appearance.pillFactor) : C.Appearance.dotSize

          Behavior on height {
            NumberAnimation { duration: C.Appearance.animMsFast; easing.type: Easing.OutCubic }
          }

          Rectangle {
            anchors.fill: parent
            radius: C.Appearance.dotSize / 2
            antialiasing: true
            color: "white"
            opacity: root.externalFocused() ? 0.95 : (root.externalOccupied() ? 0.60 : 0.35)
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.focusExternalRow()
          }
        }
      }
    }

    // ----- Bottom power button -----
    W.PowerIcon {
      id: powerIcon
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: C.Appearance.m6

      active: root.powerOpen
      onClicked: root.powerOpen = !root.powerOpen
    }
  }

  // IMPORTANT: Popup is its OWN window so it can draw outside this LeftBar lane
  W.PowerPopup {
    screen: root.screen
    open: root.powerOpen
    onDismissed: root.powerOpen = false
  }
}
