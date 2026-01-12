import QtQuick
import "../../config" as C

Rectangle {
  id: bubble

  // If >0, forces square size. If 0, bubble auto-sizes to content.
  property int bubbleSize: 0

  // NEW: only add a click-catcher if you actually want the bubble itself clickable
  property bool clickable: false

  signal clicked()

  radius: C.Appearance.bubbleRadius
  color: C.Appearance.bubbleBg
  antialiasing: true
  clip: true

  border.width: C.Appearance.bubbleBorderW
  border.color: C.Appearance.borderCol

  implicitWidth: bubbleSize > 0 ? bubbleSize : (contentBox.implicitWidth + C.Appearance.bubblePad * 2)
  implicitHeight: bubbleSize > 0 ? bubbleSize : (contentBox.implicitHeight + C.Appearance.bubblePad * 2)

  Item {
    id: contentBox
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: C.Appearance.bubblePad
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
  }

  default property alias content: contentBox.data

  // This MouseArea should NOT block children unless you explicitly want it.
  MouseArea {
    anchors.fill: parent
    enabled: bubble.clickable
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: bubble.clicked()
  }
}

