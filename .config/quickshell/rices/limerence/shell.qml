import Quickshell
import QtQuick

import "components/frame" as Frame

ShellRoot {
  Variants {
    model: Quickshell.screens

    Scope {
      required property ShellScreen modelData
      Frame.FrameRoot { screen: modelData }
    }
  }
}

