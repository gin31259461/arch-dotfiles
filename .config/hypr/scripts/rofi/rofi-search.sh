#!/usr/bin/env bash
# Provides web search functionality via Rofi interface

Search_Engine="${SEARCH_ENGINE:-https://www.google.com/search?q=}"

if ! command -v jq >/dev/null 2>&1; then
  notify-send -u low "Rofi Search" "jq is required for URL encoding. Please install jq."
  exit 1
fi

if [[ -z "$Search_Engine" ]]; then
  echo "Error: SEARCH_ENGINE is empty!"
  exit 1
fi

rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='‼️ **note** ‼️ search via default web browser'

if pgrep -x "rofi" >/dev/null; then
  pkill rofi
fi

query=$(printf '' | rofi -dmenu -config "$rofi_theme" -mesg "$msg")

if [[ -z "$query" ]]; then
  exit 0
fi

encoded_query=$(printf '%s' "$query" | jq -sRr @uri)
xdg-open "${Search_Engine}${encoded_query}" >/dev/null 2>&1 &
