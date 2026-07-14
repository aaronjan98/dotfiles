// components/widgets/NotificationCenter.qml
import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../services" as Sv
import "./" as W

Rectangle {
  id: root
  color: "transparent"
  property real scale_: 1.0

  function px(n) {
    return Math.round(n * root.scale_)
  }

  readonly property color panelBg: Qt.rgba(
    C.Appearance.bubbleBg.r,
    C.Appearance.bubbleBg.g,
    C.Appearance.bubbleBg.b,
    0.78
  )

  Rectangle {
    anchors.fill: parent
    radius: C.Appearance.frameRadius
    color: root.panelBg
    antialiasing: true
    clip: true

    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.10)

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: root.px(12)
      spacing: root.px(10)

      RowLayout {
        Layout.fillWidth: true
        spacing: root.px(10)

        Text {
          Layout.fillWidth: true
          text: "Notifications"
          color: "white"
          font.pixelSize: root.px(15)
        }

        Rectangle {
          radius: root.px(10)
          height: root.px(26)
          width: root.px(76)
          color: Sv.Notifs.dnd ? Qt.rgba(1, 0.3, 0.6, 0.30) : Qt.rgba(1, 1, 1, 0.10)
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.10)

          Text { anchors.centerIn: parent; text: Sv.Notifs.dnd ? "DND On" : "DND Off"; color: "white"; font.pixelSize: root.px(11) }
          TapHandler { onTapped: Sv.Notifs.toggleDnd() }
        }

        Rectangle {
          radius: root.px(10)
          height: root.px(26)
          width: root.px(70)
          color: Qt.rgba(1, 1, 1, 0.10)
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.10)

          Text { anchors.centerIn: parent; text: "Clear"; color: "white"; font.pixelSize: root.px(11) }
          TapHandler { onTapped: Sv.Notifs.clearAll() }
        }

        Rectangle {
          width: root.px(28); height: root.px(28)
          radius: root.px(14)
          color: Qt.rgba(1, 1, 1, 0.10)
          Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: root.px(16) }
          TapHandler { onTapped: Sv.Notifs.closeCenter() }
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        Flickable {
          anchors.fill: parent
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          contentWidth: width
          contentHeight: listCol.height

          Column {
            id: listCol
            width: parent.width
            spacing: root.px(8)

            Repeater {
              model: Sv.Notifs.history

              delegate: Item {
                width: listCol.width
                height: toast.implicitHeight

                W.NotificationToast {
                  id: toast
                  width: parent.width

                  nid_: nid
                  appName_: appName
                  summary_: summary
                  body_: body

                  iconName_: (iconName !== undefined && iconName !== null) ? iconName : ""
                  desktopEntry_: (desktopEntry !== undefined && desktopEntry !== null) ? desktopEntry : ""
                  imagePath_: (imagePath !== undefined && imagePath !== null) ? imagePath : ""

                  actionsNorm_: (actionsNorm !== undefined && actionsNorm !== null) ? actionsNorm : []
                  actions_: (actions !== undefined && actions !== null) ? actions : []
                  defaultKey_: (defaultKey !== undefined && defaultKey !== null) ? defaultKey : ""
                  scale_: root.scale_
                }
              }
            }

            Item {
              width: listCol.width
              height: root.px(80)
              visible: Sv.Notifs.history.count === 0

              Text {
                anchors.centerIn: parent
                text: "No notifications"
                color: Qt.rgba(1, 1, 1, 0.70)
                font.pixelSize: root.px(12)
              }
            }
          }
        }
      }
    }
  }
}
