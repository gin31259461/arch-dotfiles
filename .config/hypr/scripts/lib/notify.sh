#!/usr/bin/env bash
# Consistent notification helpers for scripts.

_notify_lib_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=common.sh
source "$_notify_lib_dir/common.sh"
unset _notify_lib_dir

NOTIFY_APP_NAME="${NOTIFY_APP_NAME:-Hyprland}"
NOTIFY_DEFAULT_TIMEOUT="${NOTIFY_DEFAULT_TIMEOUT:-3000}"
NOTIFY_INFO_ICON="${NOTIFY_INFO_ICON:-$(icon_img info.png)}"
NOTIFY_SUCCESS_ICON="${NOTIFY_SUCCESS_ICON:-$(icon_img ja.png)}"
NOTIFY_WARN_ICON="${NOTIFY_WARN_ICON:-$(icon_img note.png)}"
NOTIFY_ERROR_ICON="${NOTIFY_ERROR_ICON:-$(icon_img error.png)}"

_notify_send_raw() {
  if notify-send -e "$@" 2>/dev/null; then
    return 0
  fi

  notify-send "$@" 2>/dev/null || true
}

notify_message() {
  local title="$1"
  local body="${2:-}"
  local icon="${3:-$NOTIFY_INFO_ICON}"
  local urgency="${4:-low}"
  local tag="${5:-hypr-notify}"
  local timeout="${6:-$NOTIFY_DEFAULT_TIMEOUT}"

  local args=(-a "$NOTIFY_APP_NAME" -u "$urgency" -h "string:x-canonical-private-synchronous:$tag")
  [[ -n "$timeout" ]] && args+=(-t "$timeout")
  [[ -n "$icon" && -f "$icon" ]] && args+=(-i "$icon")

  _notify_send_raw "${args[@]}" "$title" "$body"
}

notify_info() {
  notify_message "$1" "${2:-}" "${3:-$NOTIFY_INFO_ICON}" low "${4:-hypr-info}" "${5:-$NOTIFY_DEFAULT_TIMEOUT}"
}

notify_success() {
  notify_message "$1" "${2:-}" "${3:-$NOTIFY_SUCCESS_ICON}" low "${4:-hypr-success}" "${5:-$NOTIFY_DEFAULT_TIMEOUT}"
}

notify_warn() {
  notify_message "$1" "${2:-}" "${3:-$NOTIFY_WARN_ICON}" normal "${4:-hypr-warn}" "${5:-$NOTIFY_DEFAULT_TIMEOUT}"
}

notify_error() {
  notify_message "$1" "${2:-}" "${3:-$NOTIFY_ERROR_ICON}" critical "${4:-hypr-error}" "${5:-$NOTIFY_DEFAULT_TIMEOUT}"
}

notify_progress() {
  local title="$1"
  local body="$2"
  local value="$3"
  local icon="${4:-$NOTIFY_INFO_ICON}"
  local tag="${5:-hypr-progress}"
  local timeout="${6:-$NOTIFY_DEFAULT_TIMEOUT}"

  local args=(
    -a "$NOTIFY_APP_NAME"
    -u low
    -h "string:x-canonical-private-synchronous:$tag"
    -h boolean:SWAYNC_BYPASS_DND:true
    -t "$timeout"
  )
  [[ "$value" =~ ^[0-9]+$ ]] && args+=(-h "int:value:$value")
  [[ -n "$icon" && -f "$icon" ]] && args+=(-i "$icon")

  _notify_send_raw "${args[@]}" "$title" "$body"
}

notify_action() {
  local title="$1"
  local body="$2"
  local icon="$3"
  local tag="${4:-hypr-action}"
  local timeout_ms="${5:-10000}"
  shift 5 || true

  local args=(
    -a "$NOTIFY_APP_NAME"
    -t "$timeout_ms"
    -h "string:x-canonical-private-synchronous:$tag"
  )
  [[ -n "$icon" && -f "$icon" ]] && args+=(-i "$icon")
  while (($#)); do
    args+=(-A "$1")
    shift
  done

  notify-send -e "${args[@]}" "$title" "$body" 2>/dev/null \
    || notify-send "${args[@]}" "$title" "$body" 2>/dev/null \
    || true
}

require_command() {
  local cmd="$1"
  local hint="${2:-Install $cmd first.}"

  if ! command_exists "$cmd"; then
    notify_error "Missing Dependency" "$hint"
    return 1
  fi
}
