import QtQuick
import "../../config" as C

Item {
  id: root

  property bool useBackground: true
  property int padX: C.Appearance.pillPadX
  property int padY: C.Appearance.pillPadY

  default property alias content: contentHost.data

  // Let padding affect size, not content position
  implicitWidth: contentHost.implicitWidth + (useBackground ? padX * 2 : 0)
  implicitHeight: contentHost.implicitHeight + (useBackground ? padY * 2 : 0)

  // Critical for Item
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    id: bg
    visible: root.useBackground
    anchors.fill: parent
    radius: C.Appearance.pillRadius
    color: C.Appearance.bubbleBg
    antialiasing: true
  
    border.width: C.Appearance.pillBorderW
    border.color: C.Appearance.pillBorderCol
  }

  Item {
    id: contentHost
    anchors.centerIn: parent

    // Make sure this item reports size from children
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
  }
}

