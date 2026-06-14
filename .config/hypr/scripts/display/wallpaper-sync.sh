#!/usr/bin/env bash
# Sync Noctalia wallpaper state for Hyprlock/rofi and refresh generated colors.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
rofi_link="$HOME/.config/rofi/.current_wallpaper"
noctalia_wallpapers="$HOME/.cache/noctalia/wallpapers.json"
effects_cache="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/effects"
wallpaper_source="$effects_cache/wallpaper-source"
wallpaper_current="$effects_cache/wallpaper-current"

get_focused_monitor() {
  if command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
  else
    hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
  fi
}

wallpaper_path=""
if [[ -f "$noctalia_wallpapers" ]]; then
  current_monitor="$(get_focused_monitor)"
  wallpaper_path="$(
    jq -r --arg monitor "$current_monitor" \
      '.wallpapers[$monitor] // .wallpapers[""] // .wallpapers["HDMI-A-1"] // empty' \
      "$noctalia_wallpapers" 2>/dev/null || true
  )"
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  exit 0
fi

ln -sf "$wallpaper_path" "$rofi_link" || true
mkdir -p "$effects_cache"
ln -sf "$wallpaper_path" "$wallpaper_source" || true
ln -sf "$wallpaper_path" "$wallpaper_current" || true
"$SCRIPT_DIR/display/generate-noctalia-theme.lua" >/dev/null 2>&1 || true
