import QtQuick
import QtQuick.Layouts

import "../../config" as C
import "../services" as Sv

Item {
  id: root

  required property int nid_
  required property string appName_
  required property string summary_
  required property string body_

  // extras
  property string iconName_: ""        // e.g. "vesktop"
  property string desktopEntry_: ""    // e.g. "vesktop"
  property string imagePath_: ""       // file://... or /path/...

  // actions
  property var actionsNorm_: []        // [{key,label}]
  property var actions_: []            // raw fallback
  property string defaultKey_: ""      // usually "default" if provided

  function headerText() {
    if (summary_ && summary_.length > 0) return summary_
    if (appName_ && appName_.length > 0) return appName_
    return ""
  }

  function messageText() {
    if (body_ && body_.length > 0) return body_
    if (summary_ && summary_.length > 0) return summary_
    return ""
  }

  implicitHeight: card.implicitHeight

  Rectangle {
    id: card
    width: parent.width
    radius: C.Appearance.bubbleRadius
    color: Qt.rgba(C.Appearance.bubbleBg.r, C.Appearance.bubbleBg.g, C.Appearance.bubbleBg.b, 0.82)
    antialiasing: true
    clip: true

    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.12)

    implicitHeight: content.implicitHeight + 20

    // Click anywhere -> activate (default action or focus pid)
    TapHandler {
      onTapped: Sv.Notifs.activate(root.nid_)
    }

    Row {
      id: content
      x: 10
      y: 10
      width: parent.width - 20
      spacing: 10

      // ---- image/icon slot ----
      Item {
        width: 34
        height: 34

        Rectangle {
          anchors.fill: parent
          radius: 10
          color: Qt.rgba(1,1,1,0.06)
          border.width: 1
          border.color: Qt.rgba(1,1,1,0.08)
        }

        // Prefer imagePath if provided (some apps provide an image-path hint)
        Image {
          anchors.fill: parent
          visible: root.imagePath_.length > 0
          source: root.imagePath_
          fillMode: Image.PreserveAspectCrop
          smooth: true
          clip: true
        }

        // Fallback glyph (since IconImage doesn't exist on your build)
        Text {
          anchors.centerIn: parent
          visible: root.imagePath_.length === 0
          // If we at least know the app, show something different than bell
          text: (root.iconName_.length > 0 || root.desktopEntry_.length > 0) ? "󰍩" : "󰂚"
          color: Qt.rgba(1,1,1,0.85)
          font.pixelSize: 16
        }
      }

      Column {
        width: parent.width - 34 - 10
        spacing: 8

        // Header row + close button
        Row {
          width: parent.width
          spacing: 8

          Text {
            width: parent.width - closeBtn.width - 8
            text: root.headerText()
            visible: text.length > 0
            color: "white"
            elide: Text.ElideRight
            font.pixelSize: 12
          }

          Rectangle {
            id: closeBtn
            width: 22
            height: 22
            radius: 11
            color: Qt.rgba(1, 1, 1, 0.10)

            Text {
              anchors.centerIn: parent
              text: "×"
              color: "white"
              font.pixelSize: 16
            }

            TapHandler {
              onTapped: Sv.Notifs.dismiss(root.nid_)
            }
          }
        }

        // Main message
        Text {
          width: parent.width
          text: root.messageText()
          wrapMode: Text.Wrap
          maximumLineCount: 7
          elide: Text.ElideRight
          color: Qt.rgba(1, 1, 1, 0.92)
          font.pixelSize: 12
          visible: text.length > 0
        }

        // Fallback if nothing at all
        Text {
          width: parent.width
          text: "—"
          color: Qt.rgba(1, 1, 1, 0.50)
          font.pixelSize: 12
          visible: (root.headerText().length === 0 && root.messageText().length === 0)
        }

        // Actions row (buttons)
        Flow {
          width: parent.width
          spacing: 6
          visible: root.actionsNorm_ && root.actionsNorm_.length > 0

          Repeater {
            model: root.actionsNorm_ || []

            delegate: Rectangle {
              radius: 10
              height: 24
              readonly property string lbl: (modelData && modelData.label) ? ("" + modelData.label) : "Action"
              readonly property string key: (modelData && modelData.key) ? ("" + modelData.key) : ""

              width: Math.max(56, Math.min(220, label.implicitWidth + 18))
              color: Qt.rgba(1, 1, 1, 0.10)
              border.width: 1
              border.color: Qt.rgba(1, 1, 1, 0.10)

              Text {
                id: label
                anchors.centerIn: parent
                text: parent.lbl
                color: "white"
                font.pixelSize: 11
                elide: Text.ElideRight
              }

              TapHandler {
                onTapped: Sv.Notifs.invoke(root.nid_, parent.key)
              }
            }
          }
        }
      }
    }
  }
}

