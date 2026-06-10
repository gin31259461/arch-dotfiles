#!/usr/bin/env bash
# Web search prompt.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

search_engine="${SEARCH_ENGINE:-https://www.google.com/search?q=}"

require_command jq "jq is required for URL encoding. Please install jq." || exit 1
require_command xdg-open "Install xdg-utils first." || exit 1

if [[ -z "$search_engine" ]]; then
  notify_error "Rofi Search" "SEARCH_ENGINE is empty."
  exit 1
fi

rofi_theme="$ROFI_CONFIG_DIR/config-search.rasi"
msg='Search with your default browser'

rofi_close_existing

query="$(printf '' | rofi_dmenu "$rofi_theme" "$msg")" || exit 0

if [[ -z "$query" ]]; then
  exit 0
fi

encoded_query=$(printf '%s' "$query" | jq -sRr @uri)
xdg-open "${search_engine}${encoded_query}" >/dev/null 2>&1 &
