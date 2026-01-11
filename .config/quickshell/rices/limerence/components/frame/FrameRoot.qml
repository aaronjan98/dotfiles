import QtQuick
import Quickshell

import "../../config" as C

Item {
  id: root
  required property ShellScreen screen

  TopBar { screen: root.screen }
  LeftBar { screen: root.screen }
  CornerPatch { screen: root.screen }
  ContentFrame { screen: root.screen }
}

