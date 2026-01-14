import QtQuick

Text {
  id: clock
  property string format: "ddd, MMM dd  HH:mm"
  text: Qt.formatDateTime(new Date(), format)

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clock.text = Qt.formatDateTime(new Date(), clock.format)
  }
}

