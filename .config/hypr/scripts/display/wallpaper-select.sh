#!/usr/bin/env bash
# Wallpaper selector: pick image or video wallpaper via rofi (SUPER W).
# Images are set with swww; videos are set with mpvpaper.

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
wallpaper_current="$HOME/.config/hypr/wallpaper-effects/.wallpaper_current"
iDIR="$HOME/.config/swaync/images"

FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION --transition-bezier $BEZIER"

if ! command -v bc &>/dev/null; then
  notify-send "bc missing" "Install package bc first"
  exit 1
fi

rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

if [[ -z "$focused_monitor" ]]; then
  notify-send "Error" "Could not detect focused monitor"
  exit 1
fi

scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')
icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

kill_for_video() {
  swww kill 2>/dev/null || true
  pgrep -x mpvpaper | xargs -r kill 2>/dev/null || true
  pgrep -x swaybg   | xargs -r kill 2>/dev/null || true
  pgrep -x hyprpaper | xargs -r kill 2>/dev/null || true
}

kill_for_image() {
  pgrep -x mpvpaper | xargs -r kill 2>/dev/null || true
  pgrep -x swaybg   | xargs -r kill 2>/dev/null || true
  pgrep -x hyprpaper | xargs -r kill 2>/dev/null || true
}

mapfile -d '' PICS < <(find -L "${wallDIR}" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" -o \
  -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.webm" \) -print0)

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"
RANDOM_PIC_NAME=". random"

menu() {
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))
  printf "%s\x00icon\x1f%s\n" "$RANDOM_PIC_NAME" "$RANDOM_PIC"
  for pic_path in "${sorted_options[@]}"; do
    pic_name=$(basename "$pic_path")
    if [[ "$pic_name" =~ \.gif$ ]]; then
      cache_gif="$HOME/.cache/gif_preview/${pic_name}.png"
      if [[ ! -f "$cache_gif" ]]; then
        mkdir -p "$HOME/.cache/gif_preview"
        magick "$pic_path[0]" -resize 1920x1080 "$cache_gif"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_gif"
    elif [[ "$pic_name" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
      cache_vid="$HOME/.cache/video_preview/${pic_name}.png"
      if [[ ! -f "$cache_vid" ]]; then
        mkdir -p "$HOME/.cache/video_preview"
        ffmpeg -v error -y -i "$pic_path" -ss 00:00:01.000 -vframes 1 "$cache_vid"
      fi
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$cache_vid"
    else
      printf "%s\x00icon\x1f%s\n" "$pic_name" "$pic_path"
    fi
  done
}

modify_startup_config() {
  :
}

apply_image_wallpaper() {
  local image_path="$1"
  kill_for_image
  if ! pgrep -x swww-daemon >/dev/null; then
    swww-daemon --format xrgb &
  fi
  swww img -o "$focused_monitor" "$image_path" $SWWW_PARAMS
  "$SCRIPTSDIR/display/wallust-swww.sh" "$image_path"
  sleep 2
  "$SCRIPTSDIR/services/refresh.sh"
}

apply_video_wallpaper() {
  local video_path="$1"
  if ! command -v mpvpaper &>/dev/null; then
    notify-send "Error" "mpvpaper not found"
    return 1
  fi
  kill_for_video
  mpvpaper '*' -o "load-scripts=no no-audio --loop" "$video_path" &
}

main() {
  choice=$(menu | rofi -i -show -dmenu -config "$rofi_theme" -theme-str "$rofi_override")
  choice=$(echo "$choice" | xargs)
  RANDOM_PIC_NAME=$(echo "$RANDOM_PIC_NAME" | xargs)

  [[ -z "$choice" ]] && exit 0

  [[ "$choice" == "$RANDOM_PIC_NAME" ]] && choice=$(basename "$RANDOM_PIC")

  choice_basename=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')
  selected_file=$(find "$wallDIR" -iname "$choice_basename.*" -print -quit)

  if [[ -z "$selected_file" ]]; then
    notify-send "Error" "Wallpaper not found: $choice"
    exit 1
  fi

  modify_startup_config "$selected_file"

  if [[ "$selected_file" =~ \.(mp4|mkv|mov|webm|MP4|MKV|MOV|WEBM)$ ]]; then
    apply_video_wallpaper "$selected_file"
  else
    apply_image_wallpaper "$selected_file"
  fi
}

pgrep -x rofi | xargs -r kill 2>/dev/null || true
main
