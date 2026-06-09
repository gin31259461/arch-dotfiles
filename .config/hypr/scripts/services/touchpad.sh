#!/usr/bin/env bash
# Manages touchpad settings and controls
# For disabling touchpad.
# Edit touchpad_device in lua/hyprconf/context.lua (use hyprctl devices to find your device name)
# use hyprctl devices to get your system touchpad device name
# source https://github.com/hyprwm/Hyprland/discussions/4283?sort=new#discussioncomment-8648109

set -euo pipefail

notif="$HOME/.config/swaync/images/ja.png"
context_lua="$HOME/.config/hypr/lua/hyprconf/context.lua"

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
    notify-send -u low -i "$notif" " Touchpad" " Device name not set (check lua/hyprconf/context.lua)"
    exit 1
fi

touchpad_keyword="${TOUCHPAD_KEYWORD:-device:${touchpad_device}:enabled}"
status_file="${XDG_RUNTIME_DIR:-/tmp}/touchpad.status"

enable_touchpad() {
    printf "true" >"$status_file"
    notify-send -u low -i "$notif" " Enabling" " touchpad"
    hyprctl keyword "$touchpad_keyword" true -r
}

disable_touchpad() {
    printf "false" >"$status_file"
    notify-send -u low -i "$notif" " Disabling" " touchpad"
    hyprctl keyword "$touchpad_keyword" false -r
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
