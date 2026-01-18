// components/services/NotifsIpc.qml
import QtQuick
import Quickshell.Io
import "./" as Sv

Item {
  visible: false

  IpcHandler {
    target: "notifs"

    function toggleCenter(): void { Sv.Notifs.toggleCenter() }
    function openCenter(): void { Sv.Notifs.openCenter() }
    function closeCenter(): void { Sv.Notifs.closeCenter() }

    function toggleDnd(): void { Sv.Notifs.toggleDnd() }
    function clearAll(): void { Sv.Notifs.clearAll() }

    // optional helpers
    function dismiss(nid: int): void { Sv.Notifs.dismiss(nid) }
    function invoke(nid: int, key: string): void { Sv.Notifs.invoke(nid, key) }
  }
}

