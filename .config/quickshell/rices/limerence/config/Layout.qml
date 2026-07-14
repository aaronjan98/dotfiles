pragma Singleton
import QtQuick
import Quickshell

QtObject {
  // The built-in laptop panel output name on the laptops in this setup.
  // Any other connected screen is treated as an external monitor.
  readonly property string laptopOutput: "eDP-1"

  function isLaptop(screen)   { return screen.name === laptopOutput }
  function isExternal(screen) { return screen.name !== laptopOutput }
}
