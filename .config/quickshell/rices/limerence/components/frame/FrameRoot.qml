import Quickshell
import QtQuick

import "./" as Frame

Item {
  id: root
  required property ShellScreen screen

  // Order matters visually: bars (interactive) on top, frame (visual-only) behind or between.
  // If your frame is masking/covering visually in the wrong place, swap ordering.

  Frame.TopBar {
    screen: root.screen
  }

  Frame.LeftBar {
    screen: root.screen
  }

  Frame.CornerPatch {
    screen: root.screen
  }

  Frame.ContentFrame {
    screen: root.screen
  }
}

