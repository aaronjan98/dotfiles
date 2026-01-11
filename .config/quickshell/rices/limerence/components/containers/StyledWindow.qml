import Quickshell
import Quickshell.Wayland

PanelWindow {
  required property string name
  WlrLayershell.namespace: `aj-${name}`

  // We'll draw everything ourselves
  color: "transparent"
}

