import QtQuick
import QtQuick.Layouts

import "../services" as Sv

Item {
  id: root
  implicitWidth: 13
  implicitHeight: 15

  // Keep it small; tune later
  Text {
    anchors.centerIn: parent
    text: "󰂚"
    color: "white"
    font.pixelSize: 14
  }

  Rectangle {
    visible: Sv.Notifs.unread > 0
    width: 8
    height: 8
    radius: 8
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: -3
    anchors.topMargin: -1
    color: Qt.rgba(1, 0.3, 0.6, 0.9)

    Text {
      anchors.centerIn: parent
      text: Sv.Notifs.unread > 9 ? "9+" : Sv.Notifs.unread.toString()
      color: "white"
      font.pixelSize: 8
    }
  }

  TapHandler {
    onTapped: Sv.Notifs.toggleCenter()
  }
}

