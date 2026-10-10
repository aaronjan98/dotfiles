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
  // nid -> invoked action key. Lifted out of the button delegate so the toast and
  // the notification center show the same "approved" state for one notification.
  // Reassigned (not mutated) on change so QML bindings re-evaluate.
  property var invokedIds: ({})

  NotificationServer {
    id: server
    // Advertise the "actions" capability so senders (notify-send --action, apps)
    // emit action buttons instead of being told actions are unsupported. The
    // toast already renders actionsNorm_ and invokes them over the bus.
    actionsSupported: true
    onNotification: (n) => root._onNotif(n)
  }

  IpcHandler {
    target: "notifs"

    function toggleCenter(): void { root.toggleCenter() }
    function openCenter(): void { root.openCenter() }
    function closeCenter(): void { root.closeCenter() }

    function toggleDnd(): void { root.toggleDnd() }
    function clearAll(): void { root.clearAll() }

    function dismiss(nid: int): void { root.dismiss(nid) }
    function invoke(nid: int, key: string): void { root.invoke(nid, key) }
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

  function _imagePath(x) {
    const s = _s(x)
    if (s.length === 0) return ""

    // Notification hints named icon-path sometimes contain an icon name or
    // desktop id, not a file. Do not hand those to QML Image as relative URLs.
    if (s[0] === "/" || s.indexOf("file://") === 0 || s.indexOf("qrc:/") === 0 || s.indexOf("qs:/") === 0) {
      return s
    }

    return ""
  }

  function _normalizeActions(n) {
    const a = n.actions
    if (!a) return []
    // n.actions is a QList<NotificationAction*>, not a JS array — Array.isArray is
    // false for it, so iterate by index/length. Each item exposes identifier/text;
    // also tolerate the legacy alternating [key, label, ...] string form.
    const len = a.length
    if (len === undefined || len === null || len <= 0) return []

    const out = []
    for (let i = 0; i < len; i++) {
      const it = a[i]
      if (it === undefined || it === null) continue
      if (typeof it === "string") {
        const skey = it
        const slabel = (typeof a[i + 1] === "string") ? a[++i] : skey
        if (skey.length > 0) out.push({ key: skey, label: slabel })
        continue
      }
      const key = _firstNonEmpty(it.identifier, it.key, it.id, it.action, it.name)
      const label = _firstNonEmpty(it.text, it.label, it.title, key)
      if (key.length > 0) out.push({ key, label })
    }
    return out
  }

  // Live, normalized actions for a delegate, looked up by notification id. A
  // ListModel can't faithfully store a JS array-of-objects (it degrades to a
  // child model exposing .count, not .length), so the toast's length check would
  // fail on the stored copy — recompute from the live notification object here.
  function actionsFor(nid) {
    const obj = _objById[nid]
    if (!obj) return []
    return _normalizeActions(obj)
  }

  function _entry(n) {
    const desktopEntry = _s(_hint(n, "desktop-entry"))
    const senderPid = _s(_hint(n, "sender-pid"))
    const iconName = _s(n.appIcon)

    const imagePath = _imagePath(_firstNonEmpty(
      _hint(n, "image-path"),
      _hint(n, "image_path"),
      _hint(n, "imagePath"),
      _hint(n, "icon-path"),
      _hint(n, "icon_path")
    ))

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
    // Retain the notification on the D-Bus server. Without this Quickshell drops
    // it as soon as this handler returns, closing it immediately — senders using
    // --wait (notify-send --action) return at once and actions can never be
    // invoked. Tracked notifications live until we expire/dismiss them below.
    try { n.tracked = true } catch (e) {}

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

    // Decouple on-screen time from bus lifetime: the toast auto-hides after a
    // short cap, but a long-lived notification stays alive on the bus for its
    // full timeout so its actions remain invokable from the notification center
    // (a waiting sender — notify-send --action — only returns once we expire it).
    const VISUAL_CAP = 15000
    const visualMs = Math.min(ms, VISUAL_CAP)
    const expireOnVisual = (ms <= visualMs)

    const tv = Qt.createQmlObject('import QtQuick; Timer { repeat: false }', root)
    tv.interval = visualMs
    tv.triggered.connect(() => {
      _remove(popupModel, e.nid)
      if (expireOnVisual) {
        const obj = _objById[e.nid]
        if (obj) { try { obj.expire() } catch (err) {} }
      }
      tv.destroy()
    })
    tv.start()

    if (!expireOnVisual) {
      const tb = Qt.createQmlObject('import QtQuick; Timer { repeat: false }', root)
      tb.interval = ms
      tb.triggered.connect(() => {
        const obj = _objById[e.nid]
        if (obj) { try { obj.expire() } catch (err) {} }
        tb.destroy()
      })
      tb.start()
    }
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
      // Notification exposes dismiss()/expire(), not close(); dismiss() is the
      // explicit user-closed path. Keeps tracked notifications from lingering.
      try { if (obj.dismiss) obj.dismiss(); else if (obj.close) obj.close() } catch (e) {}
      delete _objById[nid]
    }
    if (root.invokedIds[nid] !== undefined) {
      const next = Object.assign({}, root.invokedIds)
      delete next[nid]
      root.invokedIds = next
    }
    _remove(historyModel, nid)
    _remove(popupModel, nid)
  }

  function clearAll() {
    for (let k in _objById) {
      const o = _objById[k]
      try { if (o && o.dismiss) o.dismiss(); else if (o && o.close) o.close() } catch (e) {}
    }
    _objById = ({})
    root.invokedIds = ({})
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
          if (k === key && a.invoke) {
            // Leave the toast up so its button can show an "approved" state; the
            // notification's own expire timer clears it shortly after.
            a.invoke()
            // Record the invoked action so every view of this notification (toast
            // and center) reflects it. New object so the binding re-evaluates.
            const next = Object.assign({}, root.invokedIds)
            next[nid] = key
            root.invokedIds = next
            return
          }
        }
      }
    } catch (e) {}
  }

  function _focusPid(pid) {
    if (pid === undefined || pid === null) return
    const p = "" + pid
    if (p.length === 0) return
    hyprctl.command = ["hyprctl", "dispatch", "focuswindow", "pid:" + p]
    hyprctl.startDetached()
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
