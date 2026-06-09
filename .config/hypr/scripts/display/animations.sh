#!/usr/bin/env bash
# Configures window animation settings

if pidof rofi > /dev/null; then
  pkill rofi
fi

iDIR="$HOME/.config/swaync/images"
animations_lua="$HOME/.config/hypr/lua/hyprconf/animations.lua"
rofi_theme="$HOME/.config/rofi/config-Animations.rasi"
msg='Lua config is active. Edit lua/hyprconf/animations.lua to change animation presets.'
animations_list="Open animations.lua"

chosen_file=$(echo "$animations_list" | rofi -i -dmenu -config "$rofi_theme" -mesg "$msg")

if [[ "$chosen_file" == "Open animations.lua" ]]; then
  "${TERMINAL:-kitty}" -e "${EDITOR:-nvim}" "$animations_lua"
  notify-send -u low -i "$iDIR/ja.png" "Hyprland Animations" "Opened Lua animation config"
fi
