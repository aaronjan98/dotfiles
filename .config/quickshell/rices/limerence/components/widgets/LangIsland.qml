import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

// Language sub-island for the left-bar Kanata island (project-memory/
// kanata-island.md, Phase 2). Shows the active accent language (en/es/pt)
// behind the mode pill (KanataIsland.qml) -- same rounded shape, offset
// downward and overlapping it, darker fill. Clicking a language writes it
// via Sv.AccentCtl.setLang(), which is what the (not yet built) accent-type
// script will read on the AltGr+vowel critical path.
//
// Deliberately simpler than KanataIsland's droplet: the doc's visual design
// calls for "a small rounded rect behind the active entry that animates its
// y... same feel as DotTrack's sliding pill" -- a plain highlight Rectangle
// with a Behavior on y, not a shader. There's no stretch/elongate physics
// here because there's no analogous complaint to solve (that whole mechanism
// in KanataIsland exists to fix a specific flicker bug, not because sliding
// highlights need it by default) and no per-language tint (one tint is
// enough signal in a 2cm island -- see the doc's "does NOT tint per
// language").
Item {
  id: root

  readonly property var languages: Sv.AccentCtl.languages
  readonly property int activeIndex: Math.max(0, languages.indexOf(Sv.AccentCtl.currentLang))

  // Set by the parent (LeftBar.qml) to the mode pill's own width, so the two
  // pills line up exactly at the overlap seam. Falls back to a self-sized
  // width (rough estimate from font size) only so this widget still renders
  // something sane in isolation.
  property real matchWidth: -1

  readonly property int cellH: C.Appearance.langCellHeight
  readonly property int cellGap: C.Appearance.langCellGap
  readonly property int pad: C.Appearance.modeCellPad
  // Asymmetric on purpose -- padTop has to clear the mode pill's overlap
  // depth (langOverlap in LeftBar.qml) with room to spare; padBottom is just
  // the same thin cap padding the mode pill itself uses. See Appearance.qml.
  readonly property int padTop: C.Appearance.langPadTop
  readonly property int padBottom: C.Appearance.langPadBottom

  function trackHeight() {
    return languages.length * cellH + Math.max(0, languages.length - 1) * cellGap
  }

  implicitWidth: pill.width
  implicitHeight: pill.height

  // Plain Item now, not a Rectangle -- this is just the layout frame (what
  // `root`'s implicitWidth/Height and `track`'s positioning are relative
  // to). The actual painted shape lives entirely inside `visible` below,
  // clipped to only the portion that's NOT physically covered by the mode
  // pill. Two earlier attempts (square top corners; square corners + a
  // separately-clipped border) both still let something of this pill's OWN
  // paint show through the mode pill's translucent fill in the hidden
  // region -- first the flat fill colour, then (once the fill got a flat
  // top) the border stroke along that same edge, pixel-confirmed as a pale
  // line crossing straight through "Maj". The only way to guarantee NOTHING
  // bleeds through is to not paint anything there at all, which needs the
  // clip boundary to sit on the outside of the shape, not on the shape
  // itself (clip:true on a Rectangle only clips to its own bounding box,
  // not its rounded silhouette -- see KanataIsland.qml's header comment on
  // the same limitation -- so the shape has to be a separate child moved
  // behind a clipping frame, not try to clip itself).
  Item {
    id: pill
    anchors.horizontalCenter: parent.horizontalCenter

    width: root.matchWidth > 0
      ? root.matchWidth
      : Math.round(C.Appearance.langLetterFont * 2.6) + root.pad * 2
    height: track.height + root.padTop + root.padBottom

    // How far down from THIS pill's own top the visible clip starts.
    // langOverlap alone (how far the Column pushed this whole pill up) would
    // land the clip exactly at the mode pill's absolute bottom tip -- but the
    // mode pill's own rounded corner recedes inward well before that tip
    // (langClipRise), so clipping all the way down there left a real gap at
    // the sides where NEITHER pill painted anything. Backing off by
    // langClipRise starts the clip that much higher instead, so this pill's
    // flat top fills exactly the recess the mode pill's curve leaves behind.
    readonly property int clipDepth: Math.max(0, C.Appearance.langOverlap - C.Appearance.langClipRise)

    Item {
      id: visible
      y: pill.clipDepth
      width: pill.width
      height: pill.height - pill.clipDepth
      clip: true

      Rectangle {
        // Shifted up by the same amount `visible` shifted down, so this
        // shares pill's exact coordinate frame (and therefore its exact
        // corner geometry) -- only the part landing inside `visible`'s
        // bounds actually renders. Top corners STILL squared: now that the
        // clip starts higher (langClipRise backs it off the mode pill's own
        // curve depth, not its bottom tip), a rounded top corner would have
        // its curve partly exposed again -- back to the mismatched-crescent
        // problem a rounded top was pixel-confirmed to cause earlier. A flat
        // edge has no curve to mismatch regardless of how high the clip
        // starts, which is exactly why raising the clip to fill the side
        // gap needs this paired with squaring, not instead of it.
        y: -pill.clipDepth
        width: pill.width
        height: pill.height
        radius: C.Appearance.bubbleRadius
        topLeftRadius: 0
        topRightRadius: 0
        antialiasing: true
        // Derived from bubbleBg (not hardcoded) so it tracks the
        // wallpaper-keyed opacity logic -- "behind and darker" is the only
        // signal selling "this pill sits underneath the mode pill".
        color: Qt.darker(C.Appearance.bubbleBg, C.Appearance.langPillDarken)
        border.width: Math.max(1, C.Appearance.bubbleBorderW)
        border.color: C.Appearance.borderCol
      }
    }

    Item {
      id: track
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.padTop
      width: pill.width - root.pad * 2
      height: root.trackHeight()

      Rectangle {
        id: highlight
        width: parent.width
        height: root.cellH
        radius: C.Appearance.bubbleRadius * 0.6
        antialiasing: true
        color: C.Appearance.fgA(0.14)
        y: root.activeIndex * (root.cellH + root.cellGap)
        Behavior on y { NumberAnimation { duration: C.Appearance.animMsFast; easing.type: Easing.OutCubic } }
      }

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.cellGap

        Repeater {
          model: root.languages

          delegate: Item {
            width: track.width
            height: root.cellH

            Text {
              anchors.centerIn: parent
              text: modelData
              font.pixelSize: C.Appearance.langLetterFont
              color: index === root.activeIndex ? C.Appearance.fgDim : C.Appearance.fgA(0.35)
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Sv.AccentCtl.setLang(modelData)
            }
          }
        }
      }
    }
  }
}
