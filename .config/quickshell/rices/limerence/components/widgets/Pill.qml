import QtQuick
import "../../config" as C

Item {
  id: root

  property bool useBackground: true
  property int padX: C.Appearance.pillPadX
  property int padY: C.Appearance.pillPadY

  default property alias content: contentHost.data

  readonly property int px: useBackground ? padX : 0
  readonly property int py: useBackground ? padY : 0

  implicitWidth: contentHost.implicitWidth + px * 2
  implicitHeight: contentHost.implicitHeight + py * 2

  width: implicitWidth
  height: implicitHeight

  Rectangle {
    visible: root.useBackground
    anchors.fill: parent
    radius: C.Appearance.pillRadius
    color: C.Appearance.bubbleBg
    antialiasing: true

    // Border (matches your frame/bubble language)
    border.width: (C.Appearance.pillBorderW !== undefined) ? C.Appearance.pillBorderW : 1
    border.color: (C.Appearance.pillBorderCol !== undefined) ? C.Appearance.pillBorderCol : Qt.rgba(210/255, 190/255, 255/255, 0.35)
  }

  Item {
    id: contentHost
    anchors.centerIn: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
  }
}

