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
  property real scale_: 1.0

  function px(n) {
    return Math.round(n * root.scale_)
  }

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

    implicitHeight: content.implicitHeight + root.px(20)

    // Click anywhere -> activate (default action or focus pid)
    TapHandler {
      onTapped: Sv.Notifs.activate(root.nid_)
    }

    Row {
      id: content
      x: root.px(10)
      y: root.px(10)
      width: parent.width - root.px(20)
      spacing: root.px(10)

      // ---- image/icon slot ----
      Item {
        width: root.px(34)
        height: root.px(34)

        Rectangle {
          anchors.fill: parent
          radius: root.px(10)
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
          font.pixelSize: root.px(16)
        }
      }

      Column {
        width: parent.width - root.px(34) - root.px(10)
        spacing: root.px(8)

        // Header row + close button
        Row {
          width: parent.width
          spacing: root.px(8)

          Text {
            width: parent.width - closeBtn.width - root.px(8)
            text: root.headerText()
            visible: text.length > 0
            color: "white"
            elide: Text.ElideRight
            font.pixelSize: root.px(12)
          }

          Rectangle {
            id: closeBtn
            width: root.px(22)
            height: root.px(22)
            radius: root.px(11)
            color: Qt.rgba(1, 1, 1, 0.10)

            Text {
              anchors.centerIn: parent
              text: "×"
              color: "white"
              font.pixelSize: root.px(16)
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
          font.pixelSize: root.px(12)
          visible: text.length > 0
        }

        // Fallback if nothing at all
        Text {
          width: parent.width
          text: "—"
          color: Qt.rgba(1, 1, 1, 0.50)
          font.pixelSize: root.px(12)
          visible: (root.headerText().length === 0 && root.messageText().length === 0)
        }

        // Actions row (buttons)
        Flow {
          width: parent.width
          spacing: root.px(6)
          visible: root.actionsNorm_ && root.actionsNorm_.length > 0

          Repeater {
            model: root.actionsNorm_ || []

            delegate: Rectangle {
              radius: root.px(10)
              height: root.px(24)
              readonly property string lbl: (modelData && modelData.label) ? ("" + modelData.label) : "Action"
              readonly property string key: (modelData && modelData.key) ? ("" + modelData.key) : ""

              width: Math.max(root.px(56), Math.min(root.px(220), label.implicitWidth + root.px(18)))
              color: Qt.rgba(1, 1, 1, 0.10)
              border.width: 1
              border.color: Qt.rgba(1, 1, 1, 0.10)

              Text {
                id: label
                anchors.centerIn: parent
                text: parent.lbl
                color: "white"
                font.pixelSize: root.px(11)
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
