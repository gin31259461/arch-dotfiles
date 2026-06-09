#!/usr/bin/env bash
# Calculator interface via Rofi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

rofi_theme="$ROFI_CONFIG_DIR/config-calc.rasi"

require_command qalc "Install qalc first." || exit 1

rofi_close_existing

while true; do
  result=$(
    rofi_dmenu "$rofi_theme" "${result:-}      =    ${calc_result:-}"
  ) || exit 0

  if [[ -n "$result" ]]; then
    calc_result=$(qalc -t "$result")
    echo "$calc_result" | wl-copy
  fi
done
