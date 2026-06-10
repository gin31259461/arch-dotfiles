#!/usr/bin/env bash
# Clipboard history picker.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

rofi_theme="$ROFI_CONFIG_DIR/config-clipboard.rasi"
msg='note: Ctrl+Del = delete entry  |  Alt+Del = wipe all'

require_command cliphist "Install cliphist first." || exit 1
require_command wl-copy "Install wl-clipboard first." || exit 1

rofi_close_existing

while true; do
  status=0
  result=$(
    rofi_dmenu "$rofi_theme" "$msg" \
      -kb-custom-1 "Control-Delete" \
      -kb-custom-2 "Alt-Delete" \
      < <(cliphist list)
  ) || status=$?

  case "$status" in
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
