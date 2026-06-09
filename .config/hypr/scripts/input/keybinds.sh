#!/usr/bin/env bash
# Searchable keybinds viewer via rofi (supports bindd descriptions)

pkill yad || true
if pidof rofi > /dev/null; then
  pkill rofi
fi

binds_lua="$HOME/.config/hypr/lua/hyprconf/binds.lua"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='❗NOTE:❗ Clicking with Mouse or Pressing ENTER will have NO function'

[[ -f "$binds_lua" ]] || exit 1
display_keybinds=$(
  awk '
    /^[[:space:]]*bind(_exec)?\(/ {
      line=$0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      print line
    }
  ' "$binds_lua"
)

printf '%s\n' "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
