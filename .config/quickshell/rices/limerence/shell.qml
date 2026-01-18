import Quickshell
import QtQuick

import "components/frame" as Frame
import "components/services" as Sv

Variants {
  model: Quickshell.screens

  delegate: Item {
    // Variants will set this automatically
    required property var modelData

    // registers IPC target once per QML engine
    Sv.NotifsIpc { }

    // Pass screen explicitly (FrameRoot does NOT need modelData)
    Frame.FrameRoot {
      screen: modelData
    }
  }
}

