import QtQuick
import Quickshell.Io

// Timezone-resilient clock.
//
// A long-lived quickshell process caches the system timezone (glibc/Qt read it
// once at startup), so a naive `Qt.formatDateTime(new Date(), ...)` keeps showing
// the launch-time zone even after the OS zone changes while travelling. To stay
// correct wherever the laptop goes (automatic-timezoned swaps /etc/localtime on a
// location change), we render from the absolute epoch shifted by an offset we
// refresh from a *fresh* subprocess — and re-probe on the /etc/localtime change
// event, so no restart is ever needed.
Text {
  id: clock

  // Qt-style tokens, kept for call-site compatibility. Supported subset:
  // ddd (short day), MMM (short month), dd, HH, mm, ss.
  property string format: "ddd, MMM dd  HH:mm"

  // Minutes east of UTC for the current system zone (e.g. Maceió = -180).
  // Seed from the process-cached zone so we render sensibly before the first
  // probe returns; the probe then corrects it to the live zone.
  property int tzOffsetMinutes: -(new Date().getTimezoneOffset())

  readonly property var _days: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  readonly property var _months: ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

  function _p2(n) { return (n < 10 ? "0" : "") + n }

  function render() {
    // Absolute epoch is zone-independent; shift by the live offset, then read the
    // UTC fields to get the wall-clock time for that zone.
    var d = new Date(Date.now() + clock.tzOffsetMinutes * 60000)
    clock.text = clock.format
      .replace("ddd", clock._days[d.getUTCDay()])
      .replace("MMM", clock._months[d.getUTCMonth()])
      .replace("dd", _p2(d.getUTCDate()))
      .replace("HH", _p2(d.getUTCHours()))
      .replace("mm", _p2(d.getUTCMinutes()))
      .replace("ss", _p2(d.getUTCSeconds()))
  }

  text: ""
  Component.onCompleted: render()

  // Cheap in-process display tick — no subprocess.
  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clock.render()
  }

  // Fresh probe of the *current* system zone offset. A new process always reads
  // the current /etc/localtime, sidestepping the cached-zone problem.
  Process {
    id: tzProbe
    command: ["date", "+%z"]   // e.g. "-0300"
    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        var s = data.trim()
        if (s.length < 5) return
        var sign = s[0] === "-" ? -1 : 1
        var hh = parseInt(s.substring(1, 3))
        var mm = parseInt(s.substring(3, 5))
        if (isNaN(hh) || isNaN(mm)) return
        clock.tzOffsetMinutes = sign * (hh * 60 + mm)
        clock.render()
      }
    }
    Component.onCompleted: running = true
  }

  // Event-driven: fires the instant the OS timezone is swapped (travel), so the
  // clock corrects itself with no restart and no polling.
  FileView {
    path: "/etc/localtime"
    watchChanges: true
    printErrors: false
    onFileChanged: tzProbe.running = true
  }

  // Safety net: catches anything the file watcher misses (e.g. a symlink swap the
  // watcher doesn't see) and DST transitions, which don't touch the symlink.
  // Negligible cost — one tiny `date` every 5 minutes.
  Timer {
    interval: 300000
    running: true
    repeat: true
    onTriggered: tzProbe.running = true
  }
}
