import QtQuick
import QtQuick.Effects

Item {
  id: root

  // How thick the ring is
  property int thickness: 2

  // Rounding of the inner cutout
  property int innerRadius: 12

  // Ring color
  property color color: "#ffffff"

  anchors.fill: parent

  Rectangle {
    id: ringFill
    anchors.fill: parent
    color: root.color
    radius: 0
    antialiasing: true

    layer.enabled: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskInverted: true

      maskSource: maskItem
      // keep edge crisp
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1
    }
  }

  Item {
    id: maskItem
    anchors.fill: parent
    visible: false
    layer.enabled: true

    Rectangle {
      anchors.fill: parent
      anchors.margins: root.thickness
      radius: root.innerRadius
      antialiasing: true
    }
  }
}

