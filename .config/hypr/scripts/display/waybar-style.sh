#!/usr/bin/env bash
# Waybar style picker — select a CSS style via rofi (SUPER CTRL B)

IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

waybar_styles="$HOME/.config/waybar/style"
waybar_style="$HOME/.config/waybar/style.css"
scriptsDir="$SCRIPT_DIR"
rofi_config="$ROFI_CONFIG_DIR/config-waybar-style.rasi"
msg='Choose a Waybar style'

apply_style() {
  ln -sf "$waybar_styles/$1.css" "$waybar_style"
  reload_waybar
}

main() {
  current_name=$(basename "$(readlink -f "$waybar_style")" .css)

  mapfile -t options < <(
    find -L "$waybar_styles" -maxdepth 1 -type f -name '*.css' \
      -exec basename {} .css \; | sort
  )

  choice=$(rofi_select_marked "$rofi_config" "$msg" "$current_name" "›" "${options[@]}")

  [[ -z "$choice" ]] && exit 0
  apply_style "$choice"
}

rofi_close_existing
main
