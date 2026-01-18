pragma Singleton

import QtQuick
import Quickshell.Io
import Quickshell.Services.Notifications

Item {
  id: root
  visible: false

  property bool centerOpen: false
  property bool dnd: false
  property int unread: 0
  property bool debug: false

  ListModel { id: historyModel }
  ListModel { id: popupModel }

  property alias history: historyModel
  property alias popups: popupModel

  property var _objById: ({})

  NotificationServer {
    id: server
    onNotification: (n) => root._onNotif(n)
  }

  Process {
    id: hyprctl
    stdout: SplitParser { onRead: _ => {} }
    stderr: SplitParser { onRead: _ => {} }
  }

  function _s(x) { return (x === undefined || x === null) ? "" : ("" + x) }

  function _hint(n, key) {
    if (!n || !n.hints) return undefined
    return n.hints[key]
  }

  function _firstNonEmpty() {
    for (let i = 0; i < arguments.length; i++) {
      const v = arguments[i]
      if (v !== undefined && v !== null && ("" + v).length > 0) return v
    }
    return ""
  }

  function _normalizeActions(n) {
    const a = n.actions
    if (!a) return []

    if (Array.isArray(a) && a.length >= 2 && typeof a[0] === "string") {
      const out = []
      for (let i = 0; i + 1 < a.length; i += 2) out.push({ key: "" + a[i], label: "" + a[i + 1] })
      return out
    }

    if (Array.isArray(a) && a.length > 0 && typeof a[0] === "object") {
      const out = []
      for (let i = 0; i < a.length; i++) {
        const it = a[i]
        if (!it) continue
        const key = _firstNonEmpty(it.key, it.id, it.identifier, it.action, it.name)
        const label = _firstNonEmpty(it.label, it.text, it.title, key)
        if (key.length > 0) out.push({ key, label })
      }
      return out
    }

    return []
  }

  function _entry(n) {
    const desktopEntry = _s(_hint(n, "desktop-entry"))
    const senderPid = _hint(n, "sender-pid")
    const iconName = _s(n.appIcon)

    const imagePath = _firstNonEmpty(
      _hint(n, "image-path"),
      _hint(n, "image_path"),
      _hint(n, "imagePath"),
      _hint(n, "icon-path"),
      _hint(n, "icon_path")
    )

    const actionsNorm = _normalizeActions(n)
    const defaultKey = actionsNorm.some(x => x.key === "default") ? "default" : ""

    return {
      nid: n.id,
      appName: _s(n.appName),
      summary: _s(n.summary),
      body: _s(n.body),
      urgency: n.urgency,
      expireTimeout: n.expireTimeout,

      desktopEntry: desktopEntry,
      senderPid: senderPid,
      iconName: iconName,
      imagePath: _s(imagePath),

      actions: n.actions,
      actionsNorm: actionsNorm,
      defaultKey: defaultKey
    }
  }

  function _idx(model, nid) {
    for (let i = 0; i < model.count; i++) {
      if (model.get(i).nid === nid) return i
    }
    return -1
  }

  function _remove(model, nid) {
    const i = _idx(model, nid)
    if (i >= 0) model.remove(i)
  }

  function _onNotif(n) {
    const e = _entry(n)
    _objById[e.nid] = n

    if (root.debug) {
      console.log("[Notifs] app=", e.appName, "sum=", e.summary, "body=", e.body)
      console.log("[Notifs] iconName=", e.iconName, "desktopEntry=", e.desktopEntry, "pid=", e.senderPid, "imagePath=", e.imagePath)
      console.log("[Notifs] actionsNorm=", JSON.stringify(e.actionsNorm))
      console.log("[Notifs] hints=", JSON.stringify(n.hints))
    }

    historyModel.insert(0, e)

    const suppressPopup = root.dnd || root.centerOpen
    if (!suppressPopup) {
      popupModel.insert(0, e)
      _scheduleExpire(e)
    }

    if (!root.centerOpen) root.unread += 1
  }

  function _scheduleExpire(e) {
    let ms = e.expireTimeout
    if (ms === undefined || ms === null || ms <= 0) ms = 6000
    if (e.urgency === NotificationUrgency.Critical) return

    const t = Qt.createQmlObject('import QtQuick; Timer { repeat: false }', root)
    t.interval = ms
    t.triggered.connect(() => {
      _remove(popupModel, e.nid)
      t.destroy()
    })
    t.start()
  }

  function openCenter() {
    root.centerOpen = true
    root.unread = 0
    popupModel.clear()
  }
  function closeCenter() { root.centerOpen = false }
  function toggleCenter() { root.centerOpen ? closeCenter() : openCenter() }

  function toggleDnd() {
    root.dnd = !root.dnd
    if (root.dnd) popupModel.clear()
  }

  function dismiss(nid) {
    const obj = _objById[nid]
    if (obj) {
      try { if (obj.close) obj.close() } catch (e) {}
      delete _objById[nid]
    }
    _remove(historyModel, nid)
    _remove(popupModel, nid)
  }

  function clearAll() {
    for (let k in _objById) {
      try { if (_objById[k] && _objById[k].close) _objById[k].close() } catch (e) {}
    }
    _objById = ({})
    historyModel.clear()
    popupModel.clear()
    root.unread = 0
  }

  function invoke(nid, key) {
    const obj = _objById[nid]
    if (!obj || !key || ("" + key).length === 0) return

    try { if (obj.invoke) { obj.invoke(key); return } } catch (e) {}

    try {
      if (obj.actions && obj.actions.length !== undefined) {
        for (let i = 0; i < obj.actions.length; i++) {
          const a = obj.actions[i]
          if (!a) continue
          const k = _firstNonEmpty(a.key, a.id, a.identifier, a.action, a.name)
          if (k === key && a.invoke) { a.invoke(); return }
        }
      }
    } catch (e) {}
  }

  function _focusPid(pid) {
    if (pid === undefined || pid === null) return
    const p = "" + pid
    if (p.length === 0) return
    hyprctl.command = ["hyprctl", "dispatch", "focuswindow", "pid:" + p]
    hyprctl.start()
  }

  function activate(nid) {
    const i = _idx(historyModel, nid)
    if (i >= 0) {
      const e = historyModel.get(i)
      if (e && e.defaultKey && ("" + e.defaultKey).length > 0) {
        invoke(nid, e.defaultKey)
        return
      }
      if (e && e.senderPid !== undefined && e.senderPid !== null) {
        _focusPid(e.senderPid)
        return
      }
    }
  }
}

