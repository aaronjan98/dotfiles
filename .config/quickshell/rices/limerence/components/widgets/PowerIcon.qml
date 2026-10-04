import QtQuick
import "../../config" as C

Item {
  id: root
  property bool active: false
  signal clicked()

  // Make it tight so it doesn't overlap your frame ring.
  // This produces a consistent “even padding” look inside the left lane.
  readonly property int bubbleSize: Math.max(18, C.Appearance.leftW - 6)

  width: bubbleSize
  height: bubbleSize

  Rectangle {
    id: bubble
    anchors.fill: parent
    radius: Math.min(C.Appearance.bubbleRadius, width / 2)
    // No chip: the power glyph sits bare on the frame so it doesn't compete with
    // the (now higher-contrast) island pills. Only the active-state ring remains,
    // as feedback that the power popup is open.
    color: "transparent"
    antialiasing: true
    clip: true

    border.width: root.active ? C.Appearance.pillBorderW : 0
    border.color: root.active ? C.Appearance.pillBorderCol : "transparent"

    // Inner padding box: ensures even L/R/T/B padding visually.
    Item {
      anchors.fill: parent
      anchors.margins: 2

      Text {
        anchors.fill: parent
        text: "⏻"
        font.family: C.Appearance.iconFont
        font.pixelSize: Math.round(Math.min(parent.width, parent.height) * 0.80)
        color: C.Appearance.fg
        opacity: 0.92
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: root.clicked() }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      acceptedButtons: Qt.NoButton
    }
  }
}

