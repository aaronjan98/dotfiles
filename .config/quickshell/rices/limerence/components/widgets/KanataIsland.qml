import QtQuick
import "../../config" as C
import "../services" 1.0 as Sv

// Left-bar Kanata mode pill (project-memory/kanata-island.md, Phase 1). Shows the
// sticky layers from KanataCtl.modes as a stacked letter column with a sliding
// highlight bubble over the active one; clicking a letter switches kanata to that
// layer. The language sub-island (Phase 2) attaches BELOW this one, overlapping it,
// via negative spacing in the parent LeftBar Column -- this widget only owns the
// mode pill itself so that attachment doesn't require restructuring it later.
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
  readonly property int gap: C.Appearance.modeCellGap

  implicitWidth: pill.implicitWidth
  implicitHeight: pill.implicitHeight

  BubbleItem {
    id: pill
    anchors.horizontalCenter: parent.horizontalCenter

    Item {
      width: root.cell
      height: root.modes.length * root.cell + Math.max(0, root.modes.length - 1) * root.gap

      // Sliding highlight: a single Rectangle whose y tracks activeIndex, animated,
      // rather than a per-cell "is this the active one" state -- same technique as
      // DotTrack's pill-growth, applied to a fixed-size highlight instead.
      Rectangle {
        id: highlight
        visible: root.activeIndex >= 0
        width: root.cell
        height: root.cell
        radius: C.Appearance.bubbleRadius - C.Appearance.bubbleBorderW
        antialiasing: true
        color: root.activeIndex >= 0 ? root.modes[root.activeIndex].colour : "transparent"
        opacity: 0.85
        y: Math.max(0, root.activeIndex) * (root.cell + root.gap)

        Behavior on y { NumberAnimation { duration: C.Appearance.animMsFast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: C.Appearance.animMsFast } }
      }

      Column {
        spacing: root.gap

        Repeater {
          model: root.modes

          delegate: Item {
            id: cellItem
            width: root.cell
            height: root.cell

            readonly property bool known: Sv.KanataCtl.layers.length === 0
              || Sv.KanataCtl.layers.indexOf(modelData.key) >= 0
            readonly property bool active: index === root.activeIndex

            Text {
              anchors.centerIn: parent
              text: modelData.letter
              font.pixelSize: C.Appearance.pillFont
              font.bold: active
              color: cellItem.known
                ? (active ? C.Appearance.fg : C.Appearance.fgDim)
                : C.Appearance.fgA(0.25)
            }

            MouseArea {
              anchors.fill: parent
              enabled: cellItem.known
              hoverEnabled: cellItem.known
              cursorShape: cellItem.known ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: Sv.KanataCtl.setLayer(modelData.key)
            }
          }
        }
      }
    }
  }
}
