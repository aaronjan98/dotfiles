import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes

import "../../config" as C

PanelWindow {
  id: win
  // screen set by caller — not re-declared here to avoid shadowing PanelWindow.screen
  property bool isExternal: false

  // Inner-corner radius for the frame hole, clamped so a large frameRadius (or a
  // very small hole mid-layout) can never produce an arc bigger than the hole.
  readonly property real _r: Math.max(0, Math.min(
    C.Appearance.frameRadius,
    hole.width  / 2,
    hole.height / 2))

  // Visual-only overlay: never reserves space
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.exclusionMode: ExclusionMode.Ignore
  exclusiveZone: 0

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true

  // Click-through: empty input region
  mask: Region { }
  color: "transparent"

  // "workArea" = the intended Hyprland content region (the HOLE)
  // Everything OUTSIDE this rectangle gets tinted (the ring).
  Item {
    id: hole
    anchors.fill: parent

    // align to the same offsets your bars reserve
    anchors.leftMargin: win.isExternal ? C.Appearance.framePadLeftExternal : C.Appearance.leftW
    anchors.topMargin: win.isExternal ? C.Appearance.topHExternal : C.Appearance.topHFramework

    // allow extra frame visible on right/bottom
    anchors.rightMargin: C.Appearance.framePadRight
    anchors.bottomMargin: C.Appearance.framePadBottom
  }

  //
  // RING: a single filled Shape = full window MINUS a rounded-rect hole.
  //
  // Previously this was 4 rectangular strips butted around a SQUARE hole, with
  // the rounded inner corner only *faked* by the glow border rings below. That
  // left an untinted triangular wedge in each corner (between the square strip
  // edge and the faked arc) where the wallpaper bled through — invisible on dark
  // wallpapers, obvious on light ones. See quickshell ROADMAP "frame corner
  // gaps". Caelestia/soramane solve the same thing with geometry (ClippingRect),
  // not a shader; here one ShapePath with the odd-even fill rule fills the ring
  // right up to a genuinely rounded hole, so there is no wedge at any frameBg
  // colour. The outer subpath is the whole window; the inner subpath is a
  // rounded rect matching the hole + frameRadius; odd-even cancels their overlap.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer   // smooth AA corners (Qt 6.6+)

    ShapePath {
      fillColor: C.Appearance.frameBg
      strokeWidth: 0
      fillRule: ShapePath.OddEvenFill

      // Outer subpath: the full window rectangle.
      PathMove { x: 0;         y: 0 }
      PathLine { x: win.width; y: 0 }
      PathLine { x: win.width; y: win.height }
      PathLine { x: 0;         y: win.height }
      PathLine { x: 0;         y: 0 }

      // Inner subpath: the rounded content hole. Odd-even subtracts it.
      // r is clamped so it can never exceed half the hole's smaller side.
      PathMove { x: hole.x + win._r;                 y: hole.y }
      PathLine { x: hole.x + hole.width - win._r;    y: hole.y }
      PathArc  { x: hole.x + hole.width; y: hole.y + win._r;               radiusX: win._r; radiusY: win._r }
      PathLine { x: hole.x + hole.width; y: hole.y + hole.height - win._r }
      PathArc  { x: hole.x + hole.width - win._r; y: hole.y + hole.height; radiusX: win._r; radiusY: win._r }
      PathLine { x: hole.x + win._r;     y: hole.y + hole.height }
      PathArc  { x: hole.x;              y: hole.y + hole.height - win._r;  radiusX: win._r; radiusY: win._r }
      PathLine { x: hole.x;              y: hole.y + win._r }
      PathArc  { x: hole.x + win._r;     y: hole.y;                        radiusX: win._r; radiusY: win._r }
    }
  }

  //
  // INWARD GLOW / INNER BORDER: drawn inside the hole (so it points inward)
  //

  Item {
    id: inner
    x: hole.x
    y: hole.y
    width: hole.width
    height: hole.height

    // Outer-most inner glow
    Rectangle {
      anchors.fill: parent
      radius: C.Appearance.frameRadius
      color: "transparent"
      border.width: 1
      border.color: C.Appearance.glow1
      antialiasing: true
    }

    // Mid glow
    Rectangle {
      anchors.fill: parent
      anchors.margins: 2
      radius: Math.max(0, C.Appearance.frameRadius - 2)
      color: "transparent"
      border.width: 1
      border.color: C.Appearance.glow2
      antialiasing: true
    }

    // Inner glow
    Rectangle {
      anchors.fill: parent
      anchors.margins: 4
      radius: Math.max(0, C.Appearance.frameRadius - 4)
      color: "transparent"
      border.width: 1
      border.color: C.Appearance.glow3
      antialiasing: true
    }

    // Crisp inner ring
    Rectangle {
      anchors.fill: parent
      anchors.margins: C.Appearance.borderInset
      radius: Math.max(0, C.Appearance.frameRadius - C.Appearance.borderInset)
      color: "transparent"
      border.width: C.Appearance.border
      border.color: C.Appearance.borderCol
      antialiasing: true
    }
  }
}
