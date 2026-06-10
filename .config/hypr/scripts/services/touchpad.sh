#!/usr/bin/env bash
# Manages touchpad settings and controls
# For disabling touchpad.
# Edit touchpad_device in lua/hyprconf/context.lua (use hyprctl devices to find your device name)
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

notif="$(icon_img ja.png)"
context_lua="$HYPR_CONFIG_DIR/lua/hyprconf/context.lua"

touchpad_device="${TOUCHPAD_DEVICE:-}"
if [[ -z "$touchpad_device" && -f "$context_lua" ]]; then
  touchpad_device="$(
    awk -F= '/touchpad_device/ {
            gsub(/[[:space:]]*/, "", $1);
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2);
            gsub(/[\"'\'']/, "", $2);
            print $2;
            exit
        }' "$context_lua"
  )"
fi

if [[ -z "$touchpad_device" ]]; then
  notify_error "Touchpad" "Device name not set. Check lua/hyprconf/context.lua." "" "touchpad"
  exit 1
fi

status_file="${XDG_RUNTIME_DIR:-/tmp}/touchpad.status"

set_touchpad_enabled() {
  local enabled="$1"
  hypr_eval "hl.device({ name = $(lua_string "$touchpad_device"), enabled = $enabled })"
}

enable_touchpad() {
  printf "true" >"$status_file"
  notify_success "Touchpad" "Enabled" "$notif" "touchpad"
  set_touchpad_enabled true
}

disable_touchpad() {
  printf "false" >"$status_file"
  notify_info "Touchpad" "Disabled" "$notif" "touchpad"
  set_touchpad_enabled false
}

current_state="false"
if [[ -f "$status_file" ]]; then
  current_state="$(<"$status_file")"
fi

if [[ "$current_state" == "true" ]]; then
  disable_touchpad
else
  enable_touchpad
fi
