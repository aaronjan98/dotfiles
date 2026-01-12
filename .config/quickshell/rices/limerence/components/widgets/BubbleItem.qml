import QtQuick
import "../../config" as C

Rectangle {
  id: bubble

  // Let bars control size; default fits in the bar thickness.
  // (We reuse the SAME bubble styling tokens from Appearance.qml)
  property int bubbleSize: 0
  readonly property int _size: bubbleSize > 0 ? bubbleSize : 0

  // Click handler hook
  signal clicked()

  implicitWidth:  _size > 0 ? _size : 20
  implicitHeight: _size > 0 ? _size : 20

  radius: C.Appearance.bubbleRadius
  color: C.Appearance.bubbleBg
  antialiasing: true
  clip: true

  // You removed bubbleBorderCol previously; keep border subtle using borderCol.
  border.width: C.Appearance.bubbleBorderW
  border.color: C.Appearance.borderCol

  // Content goes inside, padded like your Nix icon container
  Item {
    id: contentBox
    anchors.fill: parent
    anchors.margins: C.Appearance.bubblePad
  }

  default property alias content: contentBox.data

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: bubble.clicked()
  }
}

