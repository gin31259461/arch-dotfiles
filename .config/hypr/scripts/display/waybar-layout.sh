#!/usr/bin/env bash
# Waybar layout picker — select a config layout via rofi (SUPER ALT B)

IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

waybar_layouts="$HOME/.config/waybar/configs"
waybar_config="$HOME/.config/waybar/config"
scriptsDir="$SCRIPT_DIR"
rofi_config="$ROFI_CONFIG_DIR/config-waybar-layout.rasi"
msg='Choose a Waybar layout'

apply_layout() {
  ln -sf "$waybar_layouts/$1" "$waybar_config"
  reload_waybar
}

main() {
  current_name=$(basename "$(readlink -f "$waybar_config")")

  mapfile -t options < <(
    find -L "$waybar_layouts" -maxdepth 1 -type f -printf '%f\n' | sort
  )

  choice=$(rofi_select_marked "$rofi_config" "$msg" "$current_name" "›" "${options[@]}")

  [[ -z "$choice" ]] && exit 0

  if [[ "$choice" == "no panel" ]]; then
    noctalia_shell_manages waybar && exit 0
    kill_by_name waybar
  else
    apply_layout "$choice"
  fi
}

rofi_close_existing
main
