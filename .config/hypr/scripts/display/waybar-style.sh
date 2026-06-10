#!/usr/bin/env bash
# Waybar style picker.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

waybar_styles="$WAYBAR_CONFIG_DIR/style"
waybar_style="$WAYBAR_CONFIG_DIR/style.css"
rofi_config="$ROFI_CONFIG_DIR/config-waybar-style.rasi"
msg='Choose a Waybar style'
marker="›"

apply_style() {
  local style="$1"
  local source_style="$waybar_styles/$style.css"

  if [[ ! -f "$source_style" ]]; then
    notify_error "Waybar Style" "Style not found: $style"
    exit 1
  fi

  ln -sf "$source_style" "$waybar_style"
  reload_waybar
  notify_success "Waybar Style" "$style applied" "$(icon_img ja.png)" "waybar-style"
}

main() {
  require_command rofi "Install rofi first." || exit 1

  if [[ ! -d "$waybar_styles" ]]; then
    notify_error "Waybar Style" "Style directory not found: $waybar_styles"
    exit 1
  fi

  local current_name choice
  local options=()

  if [[ -e "$waybar_style" ]]; then
    current_name=$(basename "$(readlink -f "$waybar_style")" .css)
  else
    current_name=""
  fi

  mapfile -t options < <(
    find -L "$waybar_styles" -maxdepth 1 -type f -name '*.css' \
      -exec basename {} .css \; | sort -V
  )

  if ((${#options[@]} == 0)); then
    notify_error "Waybar Style" "No CSS styles found in $waybar_styles"
    exit 1
  fi

  choice=$(rofi_select_marked "$rofi_config" "$msg" "$current_name" "$marker" "${options[@]}") || exit 0

  [[ -z "$choice" ]] && exit 0
  apply_style "$choice"
}

rofi_close_existing

main "$@"
