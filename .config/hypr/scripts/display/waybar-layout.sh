#!/usr/bin/env bash
# Waybar layout picker.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

waybar_layouts="$WAYBAR_CONFIG_DIR/configs"
waybar_config="$WAYBAR_CONFIG_DIR/config"
rofi_config="$ROFI_CONFIG_DIR/config-waybar-layout.rasi"
msg='Choose a Waybar layout'
marker="›"

apply_layout() {
  local layout="$1"
  local source_layout="$waybar_layouts/$layout"

  if [[ ! -f "$source_layout" ]]; then
    notify_error "Waybar Layout" "Layout not found: $layout"
    exit 1
  fi

  ln -sf "$source_layout" "$waybar_config"
  reload_waybar
  notify_success "Waybar Layout" "$layout applied" "$(icon_img ja.png)" "waybar-layout"
}

main() {
  require_command rofi "Install rofi first." || exit 1

  if [[ ! -d "$waybar_layouts" ]]; then
    notify_error "Waybar Layout" "Layout directory not found: $waybar_layouts"
    exit 1
  fi

  local current_name choice
  local options=("no panel")

  if [[ -e "$waybar_config" ]]; then
    current_name=$(basename "$(readlink -f "$waybar_config")")
  else
    current_name=""
  fi

  mapfile -t -O "${#options[@]}" options < <(
    find -L "$waybar_layouts" -maxdepth 1 -type f -printf '%f\n' | sort -V
  )

  choice=$(rofi_select_marked "$rofi_config" "$msg" "$current_name" "$marker" "${options[@]}") || exit 0

  [[ -z "$choice" ]] && exit 0

  if [[ "$choice" == "no panel" ]]; then
    if noctalia_shell_manages waybar; then
      notify_info "Waybar Layout" "Waybar is managed by Noctalia shell." "$(icon_img info.png)" "waybar-layout"
      exit 0
    fi
    kill_by_name waybar
    notify_info "Waybar Layout" "Waybar stopped." "$(icon_img note.png)" "waybar-layout"
  else
    apply_layout "$choice"
  fi
}

rofi_close_existing

main "$@"
