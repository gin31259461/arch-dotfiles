#!/usr/bin/env bash
# Shared paths and small process helpers for Hyprland scripts.

HYPR_SCRIPTS_DIR="${HYPR_SCRIPTS_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)}"
HYPR_CONFIG_DIR="${HYPR_CONFIG_DIR:-$(cd -- "$HYPR_SCRIPTS_DIR/.." && pwd -P)}"
HYPR_RUNTIME_ENV="${HYPR_RUNTIME_ENV:-$HYPR_CONFIG_DIR/.hypr-runtime.env}"
ROFI_CONFIG_DIR="${ROFI_CONFIG_DIR:-$HOME/.config/rofi}"
WAYBAR_CONFIG_DIR="${WAYBAR_CONFIG_DIR:-$HOME/.config/waybar}"
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

lua_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  printf '"%s"' "$value"
}

hypr_eval() {
  hyprctl eval "$1"
}

hypr_dispatch() {
  hypr_eval "hl.dispatch($1)"
}

hypr_set_config() {
  hypr_eval "hl.config($1)"
}

hypr_unbind() {
  hypr_eval "hl.unbind($(lua_string "$1"))"
}

hypr_bind() {
  local keys="$1"
  local dispatcher="$2"
  hypr_eval "hl.bind($(lua_string "$keys"), $dispatcher)"
}

hypr_move_window() {
  local workspace="$1"
  local window="$2"
  hypr_dispatch "hl.dsp.window.move({ workspace = $(lua_string "$workspace"), window = $(lua_string "$window") })"
}

hypr_move_window_pixel() {
  local x="$1"
  local y="$2"
  local window="$3"
  hypr_dispatch "hl.dsp.window.move({ x = $x, y = $y, window = $(lua_string "$window") })"
}

hypr_resize_window_pixel() {
  local width="$1"
  local height="$2"
  local window="$3"
  hypr_dispatch "hl.dsp.window.resize({ x = $width, y = $height, window = $(lua_string "$window") })"
}

hypr_pin_window() {
  hypr_dispatch "hl.dsp.window.pin({ window = $(lua_string "$1") })"
}

hypr_focus_window() {
  hypr_dispatch "hl.dsp.focus({ window = $(lua_string "$1") })"
}

hypr_exec_cmd() {
  local command="$1"
  local rules="${2:-}"

  if [[ -n "$rules" ]]; then
    hypr_dispatch "hl.dsp.exec_cmd($(lua_string "$command"), $rules)"
  else
    hypr_dispatch "hl.dsp.exec_cmd($(lua_string "$command"))"
  fi
}

hypr_window_rule_initial_workspace() {
  local name="$1"
  local workspace="$2"
  local match_key="$3"
  local match_value="$4"

  hypr_eval "$name = hl.window_rule({ name = $(lua_string "$name"), match = { $match_key = $(lua_string "$match_value") }, workspace = $(lua_string "$workspace silent") })"
}

hypr_disable_rule() {
  local name="$1"
  hypr_eval "if $name then $name:set_enabled(false); $name = nil end"
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

start_waybar() {
  command_exists waybar || return 0

  waybar \
    -c "$WAYBAR_CONFIG_DIR/config" \
    -s "$WAYBAR_CONFIG_DIR/style.css" \
    >/dev/null 2>&1 &
}
