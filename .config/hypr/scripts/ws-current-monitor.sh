#!/usr/bin/env bash

HYPRCTL="${HYPRCTL:-/run/current-system/sw/bin/hyprctl}"

hypr_ensure_signature() {
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE-}" ]; then
    return
  fi

  local sig_dir="/run/user/$(id -u)/hypr"
  if [ -d "$sig_dir" ]; then
    local sig
    sig="$(ls -1 "$sig_dir" 2>/dev/null | head -n1 || true)"
    if [ -n "$sig" ]; then
      export HYPRLAND_INSTANCE_SIGNATURE="$sig"
    fi
  fi
}

ws_cursor_xy() {
  local cursor_json cursor_text

  cursor_json="$("$HYPRCTL" -j cursorpos 2>/dev/null || true)"
  if jq -e . >/dev/null 2>&1 <<<"$cursor_json"; then
    jq -r '"\(.x) \(.y)"' <<<"$cursor_json"
    return
  fi

  cursor_text="$("$HYPRCTL" cursorpos 2>/dev/null || true)"
  printf '%s\n' "$cursor_text" | sed -E 's/[^0-9-]+/ /g' | awk '{print $1, $2}'
}

ws_monitor_and_workspace_under_cursor() {
  hypr_ensure_signature

  local monitors cursor x y
  monitors="$("$HYPRCTL" monitors -j 2>/dev/null || echo '[]')"
  if ! jq -e . >/dev/null 2>&1 <<<"$monitors"; then
    monitors='[]'
  fi
  if ! jq -e 'length > 0' >/dev/null 2>&1 <<<"$monitors"; then
    printf 'eDP-1 1\n'
    return
  fi

  cursor="$(ws_cursor_xy)"
  x="$(awk '{print $1}' <<<"$cursor")"
  y="$(awk '{print $2}' <<<"$cursor")"

  if ! [[ "$x" =~ ^-?[0-9]+$ ]] || ! [[ "$y" =~ ^-?[0-9]+$ ]]; then
    jq -r '[.[] | select(.focused)][0] // .[0] | "\(.name) \(.activeWorkspace.id)"' <<<"$monitors"
    return
  fi

  jq -r --argjson x "$x" --argjson y "$y" '
    ([ .[]
      | select($x >= .x and $x < (.x + .width) and $y >= .y and $y < (.y + .height))
    ][0] // [ .[] | select(.focused) ][0] // .[0])
    | "\(.name) \(.activeWorkspace.id)"
  ' <<<"$monitors"
}

ws_focused_monitor_and_workspace() {
  hypr_ensure_signature

  local monitors
  monitors="$("$HYPRCTL" monitors -j 2>/dev/null || echo '[]')"
  if ! jq -e . >/dev/null 2>&1 <<<"$monitors"; then
    monitors='[]'
  fi
  if ! jq -e 'length > 0' >/dev/null 2>&1 <<<"$monitors"; then
    printf 'eDP-1 1\n'
    return
  fi

  jq -r '[.[] | select(.focused)][0] // .[0] | "\(.name) \(.activeWorkspace.id)"' <<<"$monitors"
}

ws_logical_workspace_id() {
  local _mon="$1"
  local actual_id="$2"
  printf '%s\n' "$actual_id"
}

ws_actual_workspace_id() {
  local mon="$1"
  local logical_id="$2"
  if [[ "$mon" != "eDP-1" && "$logical_id" -le 9 ]]; then
    printf '%s\n' "$(( 100 + logical_id ))"
  else
    printf '%s\n' "$logical_id"
  fi
}

ws_workspace_jq_filter='
  def in_namespace($monitor):
    if $monitor == "eDP-1" then
      .id > 0 and .id < 100
    else
      .id >= 101 and .id <= 109
    end;
'

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cmd="${1:-debug}"

  case "$cmd" in
    debug)
      read -r mon actual_id < <(ws_monitor_and_workspace_under_cursor)
      if ! [[ "$actual_id" =~ ^[0-9]+$ ]]; then actual_id=1; fi
      logical_id="$(ws_logical_workspace_id "$mon" "$actual_id")"
      printf 'monitor=%s actual=%s logical=%s\n' "$mon" "$actual_id" "$logical_id"
      ;;
    focused)
      read -r mon actual_id < <(ws_focused_monitor_and_workspace)
      if ! [[ "$actual_id" =~ ^[0-9]+$ ]]; then actual_id=1; fi
      logical_id="$(ws_logical_workspace_id "$mon" "$actual_id")"
      printf 'monitor=%s actual=%s logical=%s\n' "$mon" "$actual_id" "$logical_id"
      ;;
    monitor)
      read -r mon _ < <(ws_focused_monitor_and_workspace)
      printf '%s\n' "$mon"
      ;;
    *)
      printf 'usage: %s [debug|focused|monitor]\n' "$0" >&2
      exit 2
      ;;
  esac
fi
