import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../services" as Sv

Item {
  id: root
  implicitWidth: C.Appearance.s(13)
  implicitHeight: C.Appearance.s(15)

  // Main bell/icon
  Text {
    anchors.centerIn: parent
    text: "󰂚"
    color: "white"
    font.family: C.Appearance.iconFont
    font.pixelSize: C.Appearance.topbarIconPx
  }

  // Unread badge
  Rectangle {
    visible: Sv.Notifs.unread > 0

    readonly property int b: C.Appearance.s(8)   // badge size
    width: b
    height: b
    radius: b

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: -C.Appearance.s(3)
    anchors.topMargin: -C.Appearance.s(1)

    color: Qt.rgba(1, 0.3, 0.6, 0.9)

    Text {
      anchors.centerIn: parent
      text: Sv.Notifs.unread > 9 ? "9+" : Sv.Notifs.unread.toString()
      color: "white"
      font.pixelSize: Math.max(1, C.Appearance.s(8))
    }
  }

  TapHandler {
    onTapped: Sv.Notifs.toggleCenter()
  }
}

