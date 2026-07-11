import Quickshell
import QtQuick
import "./" as Frame
import "../../config" as C

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

  // ---- Laptop-only components ----
  // Using Loader so the Wayland surfaces are never created on external screens.

  Loader {
    active: root.isLaptop
    sourceComponent: Component {
      Frame.LeftBar { screen: root.screen }
    }
  }

  Loader {
    active: root.isLaptop
    sourceComponent: Component {
      Frame.CornerPatch { screen: root.screen }
    }
  }

  // ---- All screens ----

  Frame.TopBar {
    screen: root.screen
    isExternal: !root.isLaptop
  }

  Frame.NotifLayer { screen: root.screen }
}
