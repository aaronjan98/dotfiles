import Quickshell
import QtQuick
import "./" as Frame

Item {
  id: root
  required property ShellScreen screen

  // Visual-only frame should be behind everything interactive.
  Frame.ContentFrame { screen: root.screen }

  // Bars above the frame (so frameBg never tints them)
  Frame.TopBar { screen: root.screen }
  Frame.LeftBar { screen: root.screen }

  // Notification toast & center window
  Frame.NotifLayer { screen: root.screen }

  // Overlay always top
  Frame.CornerPatch { screen: root.screen }
}

