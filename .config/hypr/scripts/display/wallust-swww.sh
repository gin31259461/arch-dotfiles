#!/usr/bin/env bash
# Wallust: derive colors from the current wallpaper and update templates.
# Usage: wallust-swww.sh [absolute_path_to_wallpaper]

set -euo pipefail

passed_path="${1:-}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
cache_dir="$HOME/.cache/swww/"
rofi_link="$HOME/.config/rofi/.current_wallpaper"
wallpaper_current="$(cd -- "$SCRIPT_DIR/.." && pwd -P)/wallpaper-effects/.wallpaper_current"

read_cached_wallpaper() {
  local cache_file="$1"
  if [[ -f "$cache_file" ]]; then
    awk 'NF && $0 !~ /^filter/ {print; exit}' "$cache_file"
  fi
}

read_wallpaper_from_query() {
  local monitor="$1"
  swww query | awk -v mon="$monitor" '
    /^Monitor/ { cur=$2; gsub(":", "", cur) }
    /image:/ && cur==mon { sub(/^.*image: /,""); print; exit }
  '
}

get_focused_monitor() {
  if command -v jq >/dev/null 2>&1; then
    hyprctl monitors -j | jq -r '.[] | select(.focused) | .name'
  else
    hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
  fi
}

wallpaper_path=""
if [[ -n "$passed_path" && -f "$passed_path" ]]; then
  wallpaper_path="$passed_path"
else
  current_monitor="$(get_focused_monitor)"
  cache_file="$cache_dir$current_monitor"

  for i in {1..10}; do
    [[ -f "$cache_file" ]] && break
    sleep 0.1
  done

  if [[ -f "$cache_file" ]]; then
    wallpaper_path="$(read_cached_wallpaper "$cache_file")"
  fi

  if [[ -z "$wallpaper_path" ]]; then
    wallpaper_path="$(read_wallpaper_from_query "$current_monitor")"
  fi
fi

if [[ -z "${wallpaper_path:-}" || ! -f "$wallpaper_path" ]]; then
  exit 0
fi

ln -sf "$wallpaper_path" "$rofi_link" || true
mkdir -p "$(dirname "$wallpaper_current")"
cp -f "$wallpaper_path" "$wallpaper_current" || true

mkdir -p "$HOME/.config/ghostty" || true

wait_for_templates() {
  local start_ts="$1"
  shift
  local files=("$@")
  for _ in {1..50}; do
    local ready=true
    for file in "${files[@]}"; do
      if [[ ! -s "$file" ]]; then
        ready=false
        break
      fi
      local mtime
      mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
      ((mtime < start_ts)) && {
        ready=false
        break
      }
    done
    $ready && return 0
    sleep 0.1
  done
  return 1
}

start_ts=$(date +%s)
wallust run -s "$wallpaper_path" || true
wallust_targets=(
  "$HOME/.config/waybar/wallust/colors-waybar.css"
  "$HOME/.config/rofi/wallust/colors-rofi.rasi"
)
wait_for_templates "$start_ts" "${wallust_targets[@]}" || true

if [[ -f "$HOME/.config/ghostty/wallust.conf" ]]; then
  sed -i -E 's/^(\s*palette\s*=\s*)([0-9]{1,2}):/\1\2=/' "$HOME/.config/ghostty/wallust.conf" 2>/dev/null || true
fi

for _ in 1 2 3; do
  [[ -s "$HOME/.config/ghostty/wallust.conf" ]] && break
  sleep 0.1
done
if pgrep -x ghostty >/dev/null; then
  pgrep -x ghostty | xargs -r -I{} kill -SIGUSR2 {} 2>/dev/null || true
fi

reload_waybar
