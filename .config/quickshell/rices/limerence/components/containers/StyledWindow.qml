import Quickshell
import Quickshell.Wayland

PanelWindow {
  required property string name

  property int layer: WlrLayer.Top
  property int exclusion: ExclusionMode.Auto

  WlrLayershell.namespace: `aj-${name}`
  WlrLayershell.layer: layer
  WlrLayershell.exclusionMode: exclusion

  color: "transparent"
}

