import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

// Left-bar Kanata mode pill (project-memory/kanata-island.md, Phase 1). Shows the
// sticky layers from KanataCtl.modes as a stacked column of word-blocks -- each
// mode's word (Norm/Cap/Maj) spelled downward, one letter per row -- with a glassy
// "droplet" sliding over whichever block is active; clicking a block switches
// kanata to that layer. The language sub-island (Phase 2) attaches BELOW this one,
// overlapping it, via negative spacing in the parent LeftBar Column -- this widget
// only owns the mode pill itself so that attachment doesn't require restructuring
// it later.
//
// Deliberately NOT built on W.BubbleItem: that component's shared bubblePad is too
// generous for a column this narrow (it's tuned for icon-sized content), and
// BubbleItem clips its content, which would cut off the droplet's intentional
// overflow past the pill edge. This widget uses its own slim chassis instead.
//
// The droplet itself is a real shader (kanata-droplet.frag/.vert, compiled to .qsb
// the same way components/frame/recess-shadow.frag is -- see that pair and
// docs/appearance-and-scaling.md for the qsb invocation), not stacked QML
// Rectangles, and draws a PILL/capsule SDF (same sdRoundedBox technique as
// recess-shadow.frag), not an ellipse. An ellipse was tried first and rejected:
// every point on it depends on BOTH radii, so it can't keep flat sides still
// while only growing in one direction, and its continuously-curved silhouette
// read as "blurry" even with crisp antialiasing. This build has no
// QtQuick.Effects/Qt5Compat.GraphicalEffects/QtQuick.Shapes (checked all
// three), so there's no blur/radial-gradient/arc primitive at the QML level
// either way, which is also why the reflection is a hand-rolled gaussian
// smear in the shader rather than a QML effect.
//
// The "elongate while moving" motion is NOT a single stretch-then-settle
// scalar (that version grew symmetrically up AND down from a fixed centre no
// matter which way it was actually travelling -- wrong physics, see
// `droplet.topEdge`/`bottomEdge` below). The capsule's top and bottom edges
// are two INDEPENDENTLY animated values instead: the edge in the direction of
// travel snaps to its target quickly, the other edge eases in slowly and lags
// -- that lag is the only thing that elongates the shape, and it only ever
// happens on the trailing side. radiusX (the capsule's half-width) never
// varies at all, by anyone's animation -- motion here is always vertical.
Item {
  id: root

  readonly property var modes: Sv.KanataCtl.modes
  readonly property int activeIndex: {
    for (var i = 0; i < modes.length; i++) {
      if (modes[i].key === Sv.KanataCtl.currentLayer) return i
    }
    return -1
  }
  readonly property int cell: C.Appearance.modeCellSize
  // `gap` is ONLY between different modes' word-blocks (Norm / Cap / Maj) --
  // letters within one word stack with no gap at all, hence the separate
  // zero-valued letterGap below. Keeping two names rather than one "0 sometimes"
  // value makes every call site say which kind of gap it means.
  readonly property int gap: C.Appearance.modeCellGap
  readonly property int letterGap: 0
  // pad is HORIZONTAL chassis padding (governs island width); padV is
  // VERTICAL-only (top/bottom room) -- kept separate so tuning one never
  // changes the island's width. See the Appearance.qml comments on both.
  readonly property int pad: C.Appearance.modeCellPad
  readonly property int padV: C.Appearance.modeCellPadV
  readonly property color activeColour: activeIndex >= 0 ? modes[activeIndex].colour : "transparent"

  // Each word's FIRST letter is capitalised (Norm/Cap/Maj) and sits in a full
  // `cell`-height row; the rest are lowercase and sit in a shorter row. Without
  // this, every row was the same fixed height regardless of the glyph's own ink
  // height, so lowercase letters -- visually smaller than the cell they're
  // centred in -- read as evenly, loosely spaced even with letterGap at 0; the
  // zero gap alone wasn't enough, the ROWS themselves needed to be tighter.
  readonly property int lowerCellHeight: Math.round(cell * 0.78)
  function letterRowHeight(charIndex) { return charIndex === 0 ? cell : lowerCellHeight }

  // Each mode's word is spelled DOWNWARD, one letter per row with no gap between
  // letters, so a mode's own "block" is taller the longer its word is (Norm=4
  // rows, Cap/Maj=3). These three helpers are what let the droplet, the track's
  // total height, and the click targets all agree on where each block starts and
  // how tall it is, without duplicating the per-mode row-count math in three places.
  function blockHeight(i) {
    var n = modes[i].word.length
    var h = 0
    for (var c = 0; c < n; c++) h += letterRowHeight(c)
    return h + Math.max(0, n - 1) * letterGap
  }
  function blockStartY(i) {
    var y = 0
    for (var k = 0; k < i; k++) y += blockHeight(k) + gap
    return y
  }
  function totalTrackHeight() {
    var h = 0
    for (var k = 0; k < modes.length; k++) h += blockHeight(k)
    return h + Math.max(0, modes.length - 1) * gap
  }
  // The resting capsule extends PAST the first/last letter of the active word
  // on both ends, rather than stopping exactly at the letters. Set equal to
  // `padV` itself (zero formula-level gap -- the remaining visible gap is just
  // antialiasing blur) rather than some fraction of it: a *0.85 ratio was
  // tried first and pixel-measured on a real screenshot (sampled exact border
  // rows at the chassis's top/bottom apex vs the capsule's) to still leave a
  // visible gap, because `padV` is a small integer (9px) -- a ratio's
  // rounding barely moves at that scale, so it wasn't actually tunable this
  // way. Matching padV exactly is the tightest this can go while still
  // guaranteeing (by construction) that it never exceeds the chassis.
  readonly property int vMargin: padV
  function restTop(i) { return blockStartY(i) - vMargin }
  function restBottom(i) { return blockStartY(i) + blockHeight(i) + vMargin }

  // Direction-only stretch: rather than growing a single centred capsule
  // symmetrically (which visibly grows "up AND down" no matter which way it's
  // actually travelling), the capsule's top and bottom edges are TWO
  // independently-animated values. The edge in the direction of travel (the
  // "leading" edge) snaps to its new position quickly; the other edge (the
  // "trailing" edge) eases in more slowly and visibly lags behind for a beat --
  // that lag IS the elongation, and it only ever happens on the trailing side,
  // so the capsule only ever stretches toward where it came from, never past
  // where it's going.
  onActiveIndexChanged: {
    var i = Math.max(0, activeIndex)
    var newTop = restTop(i)
    var newBottom = restBottom(i)
    var movingDown = newTop > droplet.topEdge

    topEdgeAnim.to = newTop
    bottomEdgeAnim.to = newBottom
    topEdgeAnim.duration = movingDown ? 420 : 110
    bottomEdgeAnim.duration = movingDown ? 110 : 420
    topEdgeAnim.easing.type = movingDown ? Easing.InOutCubic : Easing.OutCubic
    bottomEdgeAnim.easing.type = movingDown ? Easing.OutCubic : Easing.InOutCubic
    topEdgeAnim.restart()
    bottomEdgeAnim.restart()
  }

  implicitWidth: pill.width
  implicitHeight: pill.height

  Rectangle {
    id: pill
    anchors.horizontalCenter: parent.horizontalCenter
    clip: false   // let the droplet bleed past the chassis -- see header comment

    width: track.width + root.pad * 2
    height: track.height + root.padV * 2
    radius: C.Appearance.bubbleRadius
    antialiasing: true

    // Noticeably more transparent than the shared bubbleBg -- this pill is thin
    // enough that the chassis fill itself is a big share of what's visible, so it
    // needs to read as glass, not a painted chip.
    color: Qt.rgba(C.Appearance.bubbleBg.r, C.Appearance.bubbleBg.g,
                   C.Appearance.bubbleBg.b, C.Appearance.bubbleBg.a * 0.45)
    border.width: Math.max(1, C.Appearance.bubbleBorderW)
    border.color: C.Appearance.borderCol

    Item {
      id: track
      anchors.centerIn: parent
      width: root.cell
      height: root.totalTrackHeight()
      clip: false

      // The shader fragment only paints within THIS item's own rect (unlike the
      // old child-Rectangles, which could rely on an ancestor's clip:false to
      // overflow it) -- so this needs to be sized generously enough up front to
      // safely contain the WORST case: a direct jump between the farthest-apart
      // two blocks (e.g. Norm to Maj, skipping Cap), where the lagging trailing
      // edge can momentarily span nearly the full track before catching up.
      // Bounding it by the whole track height (plus a little margin for the rim/
      // crescent bleed) covers that regardless of how many modes are added later.
      // pill/track's clip:false is what then lets THIS item visually spill past
      // the thin chassis, same as before.
      Item {
        id: droplet
        visible: root.activeIndex >= 0
        width: Math.round(root.cell * 3.0)
        height: Math.round(root.totalTrackHeight() + root.cell * 2)
        anchors.horizontalCenter: parent.horizontalCenter
        // Rounded to a whole pixel -- centerY differs per active word (a real
        // number, not guaranteed to land on an integer), and whichever word
        // happens to rest on a fractional pixel gets a very slightly different
        // GPU rasterization/antialiasing offset than one resting on a whole
        // one. That's what showed up as "a smidge more gap at Maj specifically"
        // despite Cap and Maj being geometrically identical (same letter
        // count, same per-letter row heights) -- it was never a real height
        // shortfall, just inconsistent sub-pixel snapping between rest states.
        y: Math.round(centerY - height / 2)

        // baseRadiusX is pill's own HALF-WIDTH (Qt clamps a Rectangle's
        // rendered corner radius to min(width,height)/2, so pill's effective
        // cap radius IS pill.width/2 regardless of the larger `bubbleRadius`
        // it's declared with) MINUS a small inset, same fraction-of-pad
        // reasoning as vMargin above -- an outward margin was tried and
        // overflowed past the chassis horizontally, for the same reason
        // vMargin did vertically. This keeps it closely nested instead.
        // Never varies -- see the direction-only stretch note on
        // root.onActiveIndexChanged.
        readonly property real widthInset: 0
        readonly property real baseRadiusX: pill.width / 2 - widthInset

        // topEdge/bottomEdge are the capsule's own top and bottom Y, in track-
        // local coordinates. Each is driven by its own NumberAnimation
        // (topEdgeAnim/bottomEdgeAnim below), independently re-targeted and
        // re-timed every mode change by root.onActiveIndexChanged -- see that
        // handler for how "leading edge fast, trailing edge slow" is decided.
        // No Behavior here: these ARE the animation, not a value a Behavior
        // would separately smooth.
        property real topEdge: root.restTop(Math.max(0, root.activeIndex))
        property real bottomEdge: root.restBottom(Math.max(0, root.activeIndex))
        readonly property real centerY: (topEdge + bottomEdge) / 2
        readonly property real radiusY: (bottomEdge - topEdge) / 2

        NumberAnimation { id: topEdgeAnim; target: droplet; property: "topEdge" }
        NumberAnimation { id: bottomEdgeAnim; target: droplet; property: "bottomEdge" }

        ShaderEffect {
          anchors.fill: parent
          vertexShader: Qt.resolvedUrl("kanata-droplet.vert.qsb")
          fragmentShader: Qt.resolvedUrl("kanata-droplet.frag.qsb")

          readonly property vector2d resolution: Qt.vector2d(width, height)
          readonly property vector2d center: Qt.vector2d(width / 2, height / 2)
          readonly property real radiusX: droplet.baseRadiusX
          readonly property real radiusY: droplet.radiusY
          readonly property vector3d baseColour: Qt.vector3d(
            root.activeColour.r, root.activeColour.g, root.activeColour.b)
          readonly property real coreAlpha: 0.18
          readonly property real rimAlpha: 1.0
          readonly property real crescentAlpha: 0.14
        }
      }

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.gap

        Repeater {
          model: root.modes

          delegate: Item {
            id: wordBlock
            width: root.cell
            height: root.blockHeight(index)

            readonly property bool known: Sv.KanataCtl.layers.length === 0
              || Sv.KanataCtl.layers.indexOf(modelData.key) >= 0
            readonly property bool active: index === root.activeIndex

            Column {
              anchors.fill: parent
              spacing: root.letterGap

              Repeater {
                model: modelData.word.split("")

                delegate: Text {
                  width: root.cell
                  height: root.letterRowHeight(index)
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter
                  // NOT anchors.centerIn: that centers each glyph's own tightly-
                  // cropped ink bounds, which differs per letter shape (confirmed
                  // from a screenshot -- different letters landed at visibly
                  // different x positions even though all were "centered").
                  // Align*Center against the fixed cell uses the font's real
                  // layout metrics instead, the same reference frame for every
                  // character.
                  text: modelData
                  font.pixelSize: C.Appearance.modeLetterFont
                  color: wordBlock.known
                    ? (wordBlock.active ? C.Appearance.fg : C.Appearance.fgDim)
                    : C.Appearance.fgA(0.25)
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              enabled: wordBlock.known
              hoverEnabled: wordBlock.known
              cursorShape: wordBlock.known ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: Sv.KanataCtl.setLayer(modelData.key)
            }
          }
        }
      }
    }
  }
}
