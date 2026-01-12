import QtQuick

Item {
  id: root
  property bool active: false
  property bool occupied: false  // later you can wire this to windows>0

  // simple dot sizing
  property int dotSize: 8

  implicitWidth: dotSize
  implicitHeight: dotSize

  Rectangle {
    anchors.centerIn: parent
    width: root.dotSize
    height: root.dotSize
    radius: root.dotSize / 2
    antialiasing: true

    // Active: solid. Occupied-but-not-active: outlined. Empty: dim.
    color: root.active ? "white" : "transparent"
    border.width: root.active ? 0 : (root.occupied ? 1 : 1)
    border.color: root.occupied ? Qt.rgba(1,1,1,0.7) : Qt.rgba(1,1,1,0.25)
  }
}

