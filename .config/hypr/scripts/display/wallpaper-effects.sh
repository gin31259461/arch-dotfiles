#!/usr/bin/env bash
# Wallpaper effects: apply ImageMagick filter to current wallpaper (SUPER SHIFT W).

SCRIPTSDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPTSDIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPTSDIR/lib/rofi.sh"

wallpaper_current="$HYPR_CONFIG_DIR/wallpaper-effects/.wallpaper_current"
wallpaper_output="$HYPR_CONFIG_DIR/wallpaper-effects/.wallpaper_modified"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
rofi_theme="$ROFI_CONFIG_DIR/config-wallpaper-effect.rasi"

FPS=60
TYPE="wipe"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

declare -A effects=(
  ["No Effects"]="no-effects"
  ["Black & White"]="magick $wallpaper_current -colorspace gray -sigmoidal-contrast 10,40% $wallpaper_output"
  ["Blurred"]="magick $wallpaper_current -blur 0x10 $wallpaper_output"
  ["Charcoal"]="magick $wallpaper_current -charcoal 0x5 $wallpaper_output"
  ["Edge Detect"]="magick $wallpaper_current -edge 1 $wallpaper_output"
  ["Emboss"]="magick $wallpaper_current -emboss 0x5 $wallpaper_output"
  ["Frame Raised"]="magick $wallpaper_current +raise 150 $wallpaper_output"
  ["Frame Sunk"]="magick $wallpaper_current -raise 150 $wallpaper_output"
  ["Negate"]="magick $wallpaper_current -negate $wallpaper_output"
  ["Oil Paint"]="magick $wallpaper_current -paint 4 $wallpaper_output"
  ["Polaroid"]="magick $wallpaper_current -polaroid 0 $wallpaper_output"
  ["Posterize"]="magick $wallpaper_current -posterize 4 $wallpaper_output"
  ["Sepia Tone"]="magick $wallpaper_current -sepia-tone 65% $wallpaper_output"
  ["Sharpen"]="magick $wallpaper_current -sharpen 0x5 $wallpaper_output"
  ["Solarize"]="magick $wallpaper_current -solarize 80% $wallpaper_output"
  ["Vignette"]="magick $wallpaper_current -vignette 0x3 $wallpaper_output"
  ["Vignette-black"]="magick $wallpaper_current -background black -vignette 0x3 $wallpaper_output"
  ["Zoomed"]="magick $wallpaper_current -gravity Center -extent 1:1 $wallpaper_output"
)

no-effects() {
  swww img -o "$focused_monitor" "$wallpaper_current" $SWWW_PARAMS
  wait $!
  wallust run "$wallpaper_current" -s
  wait $!
  sleep 2
  "$SCRIPTSDIR/services/refresh.sh"
  notify_info "Wallpaper" "No effects applied" "$(icon_img note.png)" "wallpaper-effects"
  cp "$wallpaper_current" "$wallpaper_output"
}

main() {
  local options=("No Effects")
  for effect in "${!effects[@]}"; do
    [[ "$effect" != "No Effects" ]] && options+=("$effect")
  done

  local choice
  choice=$(printf "%s\n" "${options[@]}" | LC_COLLATE=C sort | rofi_dmenu "$rofi_theme" "")

  if [[ -n "$choice" ]]; then
    if [[ "$choice" == "No Effects" ]]; then
      no-effects
    elif [[ "${effects[$choice]+exists}" ]]; then
      notify_info "Wallpaper" "Applying $choice effect" "$(icon_img info.png)" "wallpaper-effects"
      eval "${effects[$choice]}"

      for pid_name in swaybg mpvpaper; do
        signal_by_name SIGUSR1 "$pid_name"
      done

      sleep 1
      swww img -o "$focused_monitor" "$wallpaper_output" $SWWW_PARAMS &
      sleep 2
      wallust run "$wallpaper_output" -s &
      sleep 1
      "$SCRIPTSDIR/services/refresh.sh"
      notify_success "Wallpaper" "$choice effect applied" "$(icon_img ja.png)" "wallpaper-effects"
    fi
  fi
}

rofi_close_existing
main
sleep 1
