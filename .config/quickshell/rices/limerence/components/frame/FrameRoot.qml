import Quickshell
import QtQuick
import "./" as Frame
import "../../config" as C
import "../services" 1.0 as Sv
import "../widgets" as W

Item {
  id: root
  required property ShellScreen screen

  readonly property bool isLaptop: C.Layout.isLaptop(screen)

  // ---- Visual frame on all screens ----
  // External screens have no LeftBar, so ContentFrame drops the left gutter.

  Frame.ContentFrame {
    screen: root.screen
    isExternal: !root.isLaptop
  }

  // ---- All screens ----

  Frame.CornerPatch {
    screen: root.screen
    isExternal: !root.isLaptop
  }

  // ---- Laptop-only components ----
  // Using Loader so the Wayland surfaces are never created on external screens.

  Loader {
    active: root.isLaptop
    sourceComponent: Component {
      Item {
        Frame.LeftBar { screen: root.screen }

        // AccentIpc/AccentPanel (project-memory/kanata-island.md, Phase 2)
        // live HERE, not as siblings of FrameRoot itself: FrameRoot is
        // created once PER SCREEN (shell.qml's Variants over
        // Quickshell.screens), and an IpcHandler's target name has to be
        // unique process-wide -- putting AccentIpc directly in FrameRoot
        // would try to register "accent" once per screen and collide on
        // any dual-screen setup. This Loader is already gated to exactly
        // one (laptop) screen, which is also the only screen the accent
        // panel should ever appear on (it's anchored off LeftBar's own
        // leftW, which doesn't exist on external screens).
        Sv.AccentIpc {}
        W.AccentPanel { screen: root.screen }
      }
    }
  }

  Frame.TopBar {
    screen: root.screen
    isExternal: !root.isLaptop
  }

  Frame.NotifLayer { screen: root.screen }
}
