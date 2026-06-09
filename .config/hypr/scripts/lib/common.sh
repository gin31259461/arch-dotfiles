#!/usr/bin/env bash
# Shared paths and small process helpers for Hyprland scripts.

HYPR_SCRIPTS_DIR="${HYPR_SCRIPTS_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)}"
HYPR_CONFIG_DIR="${HYPR_CONFIG_DIR:-$(cd -- "$HYPR_SCRIPTS_DIR/.." && pwd -P)}"
ROFI_CONFIG_DIR="${ROFI_CONFIG_DIR:-$HOME/.config/rofi}"
SWAYNC_CONFIG_DIR="${SWAYNC_CONFIG_DIR:-$HOME/.config/swaync}"
SWAYNC_IMAGE_DIR="${SWAYNC_IMAGE_DIR:-$SWAYNC_CONFIG_DIR/images}"
SWAYNC_ICON_DIR="${SWAYNC_ICON_DIR:-$SWAYNC_CONFIG_DIR/icons}"

icon_img() {
  printf '%s/%s\n' "$SWAYNC_IMAGE_DIR" "$1"
}

icon_symbol() {
  printf '%s/%s\n' "$SWAYNC_ICON_DIR" "$1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

kill_by_name() {
  local proc
  for proc in "$@"; do
    pkill -x "$proc" 2>/dev/null || true
  done
}

signal_by_name() {
  local signal="$1"
  shift

  local proc
  for proc in "$@"; do
    pgrep -x "$proc" | xargs -r -I{} kill "-$signal" {} 2>/dev/null || true
  done
}

reload_waybar() {
  if command_exists waybar-msg; then
    waybar-msg cmd reload >/dev/null 2>&1 || true
  elif pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
  fi
}
