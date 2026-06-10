#!/usr/bin/env bash
# Shared paths and small process helpers for Hyprland scripts.

HYPR_SCRIPTS_DIR="${HYPR_SCRIPTS_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)}"
HYPR_CONFIG_DIR="${HYPR_CONFIG_DIR:-$(cd -- "$HYPR_SCRIPTS_DIR/.." && pwd -P)}"
HYPR_RUNTIME_ENV="${HYPR_RUNTIME_ENV:-$HYPR_CONFIG_DIR/.hypr-runtime.env}"
ROFI_CONFIG_DIR="${ROFI_CONFIG_DIR:-$HOME/.config/rofi}"
SWAYNC_CONFIG_DIR="${SWAYNC_CONFIG_DIR:-$HOME/.config/swaync}"
SWAYNC_IMAGE_DIR="${SWAYNC_IMAGE_DIR:-$SWAYNC_CONFIG_DIR/images}"
SWAYNC_ICON_DIR="${SWAYNC_ICON_DIR:-$SWAYNC_CONFIG_DIR/icons}"
RAINBOW_BORDER_MODE_FILE="${RAINBOW_BORDER_MODE_FILE:-$HYPR_CONFIG_DIR/wallpaper-effects/.rainbow_border_mode}"

NOCTALIA_SHELL_ENABLED="${NOCTALIA_SHELL_ENABLED:-1}"
NOCTALIA_SHELL_MANAGES_WAYBAR="${NOCTALIA_SHELL_MANAGES_WAYBAR:-1}"
if [[ -r "$HYPR_RUNTIME_ENV" ]]; then
  # shellcheck source=/dev/null
  source "$HYPR_RUNTIME_ENV"
fi

icon_img() {
  printf '%s/%s\n' "$SWAYNC_IMAGE_DIR" "$1"
}

icon_symbol() {
  printf '%s/%s\n' "$SWAYNC_ICON_DIR" "$1"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

truthy() {
  case "${1:-}" in
    1 | true | yes | on) return 0 ;;
    *) return 1 ;;
  esac
}

noctalia_shell_enabled() {
  truthy "$NOCTALIA_SHELL_ENABLED"
}

noctalia_shell_manages() {
  local module="$1"

  case "$module" in
    waybar) truthy "$NOCTALIA_SHELL_MANAGES_WAYBAR" ;;
    *) return 1 ;;
  esac
}

rainbow_border_mode() {
  local mode

  if [[ -f "$RAINBOW_BORDER_MODE_FILE" ]]; then
    IFS= read -r mode <"$RAINBOW_BORDER_MODE_FILE" || mode=""
  else
    mode="disabled"
  fi

  case "$mode" in
    gradient_flow | rainbow | wallust_random | disabled) printf '%s\n' "$mode" ;;
    *) printf '%s\n' disabled ;;
  esac
}

rainbow_border_enabled() {
  case "$(rainbow_border_mode)" in
    gradient_flow | rainbow | wallust_random) return 0 ;;
    *) return 1 ;;
  esac
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
  noctalia_shell_manages waybar && return 0

  if command_exists waybar-msg; then
    waybar-msg cmd reload >/dev/null 2>&1 || true
  elif pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
  fi
}
