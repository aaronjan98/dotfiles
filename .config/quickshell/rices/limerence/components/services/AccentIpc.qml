// components/services/AccentIpc.qml
import QtQuick
import Quickshell.Io
import "./" as Sv

// `qs ipc call accent ...` entry points for the accent-type/accent-cycle/
// accent-commit scripts (project-memory/kanata-island.md, Phase 2) to drive
// the display-only AccentPanel. Instantiated once from FrameRoot.qml's
// laptop-only Loader (NOT per-screen) -- an IpcHandler target name has to
// be unique process-wide, and FrameRoot itself is created once per screen
// (shell.qml's Variants over Quickshell.screens), so putting this directly
// in FrameRoot would try to register "accent" twice on a dual-screen setup.
Item {
  visible: false

  IpcHandler {
    target: "accent"

    function present(base: string, variants: string, index: int): void {
      Sv.AccentCtl.show(base, variants, index)
    }
    function select(index: int): void { Sv.AccentCtl.select(index) }
    function hide(): void { Sv.AccentCtl.hide() }
  }
}
