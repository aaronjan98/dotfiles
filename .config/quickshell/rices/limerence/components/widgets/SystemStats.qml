import QtQuick
import Quickshell.Io

Item {
  id: root

  // exposed values
  property int cpuUsage: 0
  property int memUsage: 0

  // cpu calculation state
  property double lastCpuIdle: 0
  property double lastCpuTotal: 0

  // --- CPU: read /proc/stat ---
  Process {
    id: cpuProc
    command: ["sh", "-c", "head -1 /proc/stat"]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        var p = data.trim().split(/\s+/)   // cpu user nice system idle iowait irq softirq ...
        if (p.length < 8) return

        var user = parseInt(p[1]) || 0
        var nice = parseInt(p[2]) || 0
        var system = parseInt(p[3]) || 0
        var idle = parseInt(p[4]) || 0
        var iowait = parseInt(p[5]) || 0
        var irq = parseInt(p[6]) || 0
        var softirq = parseInt(p[7]) || 0

        var idleAll = idle + iowait
        var total = user + nice + system + idle + iowait + irq + softirq

        if (root.lastCpuTotal > 0) {
          var dTotal = total - root.lastCpuTotal
          var dIdle = idleAll - root.lastCpuIdle
          if (dTotal > 0) root.cpuUsage = Math.round(100 * (1 - (dIdle / dTotal)))
        }

        root.lastCpuTotal = total
        root.lastCpuIdle = idleAll
      }
    }
    Component.onCompleted: running = true
  }

  // --- MEM: read /proc/meminfo (no dependency on `free`) ---
  Process {
    id: memProc
    command: ["sh", "-c", "awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END { if(t>0) printf(\"%d\\n\", (100*(t-a)/t)); else print 0 }' /proc/meminfo"]
    stdout: SplitParser {
      onRead: data => {
        if (!data) return
        var v = parseInt(data.trim())
        if (!isNaN(v)) root.memUsage = v
      }
    }
    Component.onCompleted: running = true
  }

  // update loop
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      memProc.running = true
    }
  }
}

