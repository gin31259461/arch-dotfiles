#!/usr/bin/env bash
# Provides web search functionality via Rofi interface

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

Search_Engine="${SEARCH_ENGINE:-https://www.google.com/search?q=}"

require_command jq "jq is required for URL encoding. Please install jq." || exit 1

if [[ -z "$Search_Engine" ]]; then
  echo "Error: SEARCH_ENGINE is empty!"
  exit 1
fi

rofi_theme="$ROFI_CONFIG_DIR/config-search.rasi"
msg='Search with your default browser'

rofi_close_existing

query=$(printf '' | rofi_dmenu "$rofi_theme" "$msg")

if [[ -z "$query" ]]; then
  exit 0
fi

encoded_query=$(printf '%s' "$query" | jq -sRr @uri)
xdg-open "${Search_Engine}${encoded_query}" >/dev/null 2>&1 &
