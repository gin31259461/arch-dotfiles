#!/usr/bin/env bash
# Manages clipboard with history functionality

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

# Variables
rofi_theme="$ROFI_CONFIG_DIR/config-clipboard.rasi"
msg='note: Ctrl+Del = delete entry  |  Alt+Del = wipe all'
# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents

rofi_close_existing

while true; do
  result=$(
    rofi_dmenu "$rofi_theme" "$msg" \
      -kb-custom-1 "Control-Delete" \
      -kb-custom-2 "Alt-Delete" \
      < <(cliphist list)
  )

  case "$?" in
    1)
      exit
      ;;
    0)
      case "$result" in
        "")
          continue
          ;;
        *)
          cliphist decode <<<"$result" | wl-copy
          exit
          ;;
      esac
      ;;
    10)
      cliphist delete <<<"$result"
      ;;
    11)
      cliphist wipe
      ;;
  esac
done
