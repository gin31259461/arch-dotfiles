#!/usr/bin/env bash
# Random wallpaper: pick a random image from wallDIR and apply with swww (CTRL ALT W).

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

mapfile -t PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.pnm" -o \
  -iname "*.tga" -o -iname "*.tiff" -o -iname "*.webp" -o -iname "*.bmp" -o \
  -iname "*.farbfeld" -o -iname "*.gif" \))

RANDOMPIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"

FPS=30
TYPE="random"
DURATION=1
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

swww query || swww-daemon --format xrgb
swww img -o "$focused_monitor" "$RANDOMPIC" $SWWW_PARAMS
wait $!
"$SCRIPTSDIR/display/wallust-swww.sh" "$RANDOMPIC"
wait $!
sleep 2
"$SCRIPTSDIR/services/refresh.sh"
