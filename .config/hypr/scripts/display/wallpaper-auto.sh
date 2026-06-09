#!/usr/bin/env bash
# Auto wallpaper: cycle through wallDIR randomly every INTERVAL seconds.
# Usage: wallpaper-auto.sh <directory>
# Example: wallpaper-auto.sh $HOME/Pictures/wallpapers

SCRIPTSDIR="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')

if [[ $# -lt 1 ]] || [[ ! -d "$1" ]]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_TYPE=simple

INTERVAL=1800 # seconds between wallpaper changes

while true; do
  find "$1" \
    | while read -r img; do echo "$((RANDOM % 1000)):$img"; done \
    | sort -n | cut -d':' -f2- \
    | while read -r img; do
      swww img -o "$focused_monitor" "$img"
      "$SCRIPTSDIR/display/wallust-swww.sh" "$img"
      "$SCRIPTSDIR/services/refresh.sh"
      sleep $INTERVAL
    done
done
