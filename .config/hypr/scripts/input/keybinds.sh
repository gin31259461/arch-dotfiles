#!/usr/bin/env bash
# Searchable keybinds viewer via rofi (supports bindd descriptions)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

kill_by_name yad
rofi_close_existing

binds_lua="$HYPR_CONFIG_DIR/lua/hyprconf/binds.lua"
rofi_theme="$ROFI_CONFIG_DIR/config-keybinds.rasi"
msg='Browse keybinds'

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

printf '%s\n' "$display_keybinds" | rofi_dmenu "$rofi_theme" "$msg"
