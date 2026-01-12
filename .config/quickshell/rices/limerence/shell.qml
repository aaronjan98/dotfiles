import Quickshell
import QtQuick

import "components/frame" as Frame

Variants {
  model: Quickshell.screens

  delegate: Item {
    // Variants will set this automatically
    required property var modelData

    // Pass screen explicitly (FrameRoot does NOT need modelData)
    Frame.FrameRoot {
      screen: modelData
    }
  }
}

