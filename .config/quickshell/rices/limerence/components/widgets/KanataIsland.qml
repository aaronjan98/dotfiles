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
//
// The droplet carries its own crossfaded tint (droplet.tint below) -- the
// active mode's saturated hue, eased rather than snapped. A texture-sampling
// "lens" version was tried (sample the backdrop+letters through a
// ShaderEffectSource and boost their own alpha, instead of painting a flat
// tint) and rejected on sight: the letters visibly doubled/ghosted at the
// mask's antialiased edge, the result read as too bright/flat, and the rim
// read as a thick border once the interior was that bright too. Back to a
// flat tint, which is the version actually liked.
Item {
  id: root

  readonly property var modes: Sv.KanataCtl.modes
  // currentLayer isn't always one of `modes` -- "nums" and "arrows" are
  // layer-while-held, momentarily engaged by ordinary tap-hold KEYS used
  // constantly during normal typing (holding space a beat engages nums,
  // holding v engages arrows -- see kanata-internal.kbd), and are
  // deliberately excluded from `modes` itself so they don't show up as a
  // fourth/fifth word. That exclusion alone doesn't stop currentLayer from
  // actually BECOMING "nums"/"arrows" for that moment though -- rawIndex
  // resolves to -1 then, and this WAS what `activeIndex` used directly,
  // which fed straight into `visible: activeIndex >= 0` on the droplet: the
  // indicator vanished completely every time the user merely held space or
  // v for a beat while typing, nothing to do with actually switching modes.
  // Confirmed by forcing currentLayer to "nums" directly and watching the
  // droplet disappear entirely. activeIndex now only UPDATES when rawIndex
  // really is a known mode -- a momentary excursion to nums/arrows just
  // never touches it, so the droplet keeps resting exactly where it was.
  readonly property int rawIndex: {
    for (var i = 0; i < modes.length; i++) {
      if (modes[i].key === Sv.KanataCtl.currentLayer) return i
    }
    return -1
  }
  // Plain literal initial value (0 == "default", matching KanataCtl's own
  // initial currentLayer), NOT `: rawIndex` -- that would create a LIVE
  // binding rather than a one-time initial value (the same pitfall flagged
  // on droplet.topEdge/bottomEdge elsewhere in this file), which would keep
  // tracking rawIndex -- including down to -1 -- until the very first
  // onRawIndexChanged assignment below happens to break it. A literal has
  // no dependency to track, so the guard below is in full control from the
  // first frame, not just after the first real mode switch.
  property int activeIndex: 0
  onRawIndexChanged: if (rawIndex >= 0) activeIndex = rawIndex
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
    // Back to the original 110ms leading edge. It was slowed to 200, then
    // 300ms chasing "it jumps to the destination immediately and then
    // animates from where it's supposed to" -- but that symptom was never
    // about this duration at all. The REAL cause was topEdge/bottomEdge
    // being declared as live bindings (`: root.restTop(...)`), which
    // snapped them straight to the new target the instant activeIndex
    // changed, racing these very animations -- fixed at the property
    // declaration itself (see topEdge/bottomEdge below). Slowing the
    // leading edge down never touched that race; it just gave the glitch
    // frame more time to be visible, which is why it got WORSE, not
    // better. Reverting to 110ms now that the actual bug is gone.
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
      // Per-mode colour lives HERE, as ONE continuous backdrop painted on the
      // chassis itself, independent of the droplet's own tint below. Two
      // plain-QML attempts at this backdrop were rejected on inspection
      // before it became a shader: three separate rounded-pill Rectangles
      // (one per word) read as disconnected chips with a gap at every seam;
      // a single Rectangle{clip:true; radius:...} around a Column of flat
      // per-word Rectangles looked right in a mock-up but clip did not
      // actually mask children to the rounded radius (empty black domes at
      // the top/bottom caps), and the colour blend between words was a
      // literal QML Gradient painted over too few real device pixels to
      // read as a fade. A hand SDF mask (same sdRoundedBox technique as
      // kanata-droplet.frag/recess-shadow.frag, see kanata-trackbg.frag)
      // sidesteps both.
      Item {
        id: trackBg
        width: pill.width
        // Extends by vMargin top AND bottom, matching pill's own padding
        // exactly (pill.height == track.height + padV*2, and vMargin ==
        // padV) -- NOT just totalTrackHeight(). The droplet's own rest
        // position already pokes vMargin past the first/last letter row
        // (restTop/restBottom), which is also where the chassis's own
        // rounded cap visually sits; sizing trackBg to only the letters'
        // own span left that whole top/bottom cap area outside its rendered
        // rect entirely, which is why an earlier version showed up empty/
        // black there no matter how the shader's own mask was tuned.
        height: root.totalTrackHeight() + root.vMargin * 2
        y: -root.vMargin
        anchors.horizontalCenter: parent.horizontalCenter

        ShaderEffect {
          anchors.fill: parent
          vertexShader: Qt.resolvedUrl("kanata-trackbg.vert.qsb")
          fragmentShader: Qt.resolvedUrl("kanata-trackbg.frag.qsb")

          readonly property vector2d resolution: Qt.vector2d(width, height)
          readonly property vector2d center: Qt.vector2d(width / 2, height / 2)
          readonly property real radiusX: width / 2
          readonly property real radiusY: height / 2
          readonly property vector3d colourA: Qt.vector3d(
            root.modes[0].colour.r, root.modes[0].colour.g, root.modes[0].colour.b)
          readonly property vector3d colourB: Qt.vector3d(
            root.modes[1].colour.r, root.modes[1].colour.g, root.modes[1].colour.b)
          readonly property vector3d colourC: Qt.vector3d(
            root.modes[2].colour.r, root.modes[2].colour.g, root.modes[2].colour.b)
          // Midpoint of the `gap` between word i and word i+1 -- where each
          // fade is centred. +vMargin converts from track-local Y (0 at the
          // first letter row) into this item's OWN local Y (0 at its top,
          // which now sits vMargin above the first letter row -- see the
          // height/y comment on trackBg above).
          readonly property real boundary0: root.blockStartY(1) - root.gap / 2 + root.vMargin
          readonly property real boundary1: root.blockStartY(2) - root.gap / 2 + root.vMargin
          // Wider than the literal `gap` on purpose -- at `gap` exactly, the
          // fade is real but spans too few device pixels at this UI scale to
          // read as gradual; widening it just makes the SAME fade more
          // visually obvious without touching the actual word spacing.
          readonly property real transitionWidth: root.gap * 1.6
          readonly property real fillAlpha: C.Appearance.modeZoneAlpha
        }
      }

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
        //
        // Plain literal initial values (0), NOT `: root.restTop(...)` --
        // THAT was a live binding (the same pitfall already fixed on
        // root.activeIndex above), and it is what caused "it jumps to the
        // destination immediately and then animates from where it's
        // supposed to": the instant root.activeIndex changed, this binding
        // re-evaluated and snapped topEdge/bottomEdge straight to the NEW
        // rest position in the SAME tick, racing the NumberAnimations
        // below -- confirmed by logging topEdge/bottomEdge frame-by-frame
        // during a real click: both jumped to the exact new target for one
        // frame, then jumped back toward the old value, and only THEN did
        // the actual animation play from there. A literal has no dependency
        // to race with, so Component.onCompleted below sets the correct
        // STARTING value once, imperatively, and the two NumberAnimations
        // are the only thing that ever touches these properties after that.
        property real topEdge: 0
        property real bottomEdge: 0
        Component.onCompleted: {
          topEdge = root.restTop(Math.max(0, root.activeIndex))
          bottomEdge = root.restBottom(Math.max(0, root.activeIndex))
        }
        readonly property real centerY: (topEdge + bottomEdge) / 2
        readonly property real radiusY: (bottomEdge - topEdge) / 2

        NumberAnimation { id: topEdgeAnim; target: droplet; property: "topEdge" }
        NumberAnimation { id: bottomEdgeAnim; target: droplet; property: "bottomEdge" }

        // The droplet's own tint -- the active mode's saturated hue,
        // crossfaded rather than snapped. Binding baseColour straight to
        // root.activeColour snaps the hue the instant activeIndex changes,
        // same frame, regardless of how slowly the shape itself animates.
        // Routing it through this colour property WITH a Behavior keeps the
        // colour but turns that snap into an actual crossfade.
        // Easing.InCubic (a bezier that starts flat and accelerates into
        // the end) gives it a "sticks around longer and then disappears
        // quickly" shape for the OLD hue -- tint barely moves off it for the
        // first chunk of the duration, then rushes to the new one right at
        // the end. Because it's a single mix(old,new,t) driven by one eased
        // t, the NEW hue's arrival is automatically the mirror of that same
        // shape for the destination, with no second animation needed.
        property color tint: root.activeIndex >= 0 ? root.modes[root.activeIndex].colour : C.Appearance.fg
        Behavior on tint {
          ColorAnimation { duration: 480; easing.type: Easing.InCubic }
        }

        ShaderEffect {
          anchors.fill: parent
          vertexShader: Qt.resolvedUrl("kanata-droplet.vert.qsb")
          fragmentShader: Qt.resolvedUrl("kanata-droplet.frag.qsb")

          readonly property vector2d resolution: Qt.vector2d(width, height)
          readonly property vector2d center: Qt.vector2d(width / 2, height / 2)
          readonly property real radiusX: droplet.baseRadiusX
          readonly property real radiusY: droplet.radiusY
          // droplet.tint is the crossfaded colour (see the Behavior above) --
          // the mode's own saturated hue.
          readonly property vector3d baseColour: Qt.vector3d(
            droplet.tint.r, droplet.tint.g, droplet.tint.b)
          readonly property real coreAlpha: 0.55
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
                  // No more active/inactive brightness distinction -- always
                  // the same dim colour regardless of whether the droplet is
                  // currently over this word. Experiment: the previous
                  // active-triggered fg/fgDim swap (even eased over 650ms via
                  // a Behavior) was a SECOND thing changing in sync with the
                  // mode switch, on top of the droplet's own tint crossfade
                  // and position/stretch animation -- removing it tests
                  // whether that second, simultaneous change was itself part
                  // of what read as "blinking".
                  color: wordBlock.known ? C.Appearance.fgDim : C.Appearance.fgA(0.25)
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
