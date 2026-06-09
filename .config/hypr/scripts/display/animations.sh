#!/usr/bin/env bash
# Configures window animation settings

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

rofi_close_existing

animations_lua="$HYPR_CONFIG_DIR/lua/hyprconf/animations.lua"
rofi_theme="$ROFI_CONFIG_DIR/config-Animations.rasi"
msg='Lua config is active. Edit lua/hyprconf/animations.lua to change animation presets.'
animations_list="Open animations.lua"

chosen_file=$(echo "$animations_list" | rofi_dmenu "$rofi_theme" "$msg")

if [[ "$chosen_file" == "Open animations.lua" ]]; then
  "${TERMINAL:-kitty}" -e "${EDITOR:-nvim}" "$animations_lua"
  notify_success "Hyprland Animations" "Opened Lua animation config" "$(icon_img ja.png)" "animations"
fi
