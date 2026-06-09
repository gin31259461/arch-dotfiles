#!/usr/bin/env bash
# Controls keyboard backlight brightness

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

iDIR="$SWAYNC_ICON_DIR"

# Get keyboard brightness
get_kbd_backlight() {
  echo "$(brightnessctl -d '*::kbd_backlight' -m | cut -d, -f4)"
}

# Get icon matching current brightness level
get_icon() {
  current=$(get_kbd_backlight | sed 's/%//')
  if [[ "$current" -le 20 ]]; then
    icon="$iDIR/brightness-20.png"
  elif [[ "$current" -le 40 ]]; then
    icon="$iDIR/brightness-40.png"
  elif [[ "$current" -le 60 ]]; then
    icon="$iDIR/brightness-60.png"
  elif [[ "$current" -le 80 ]]; then
    icon="$iDIR/brightness-80.png"
  else
    icon="$iDIR/brightness-100.png"
  fi
}

# Notify user of current brightness
notify_user() {
  notify_progress "Keyboard Brightness" "${current}%" "$current" "$icon" "keyboard_brightness_notif"
}

# Change brightness and notify
change_kbd_backlight() {
  brightnessctl -d '*::kbd_backlight' set "$1" && get_icon && notify_user
}

case "$1" in
  "--get")
    get_kbd_backlight
    ;;
  "--inc")
    change_kbd_backlight "+30%"
    ;;
  "--dec")
    change_kbd_backlight "30%-"
    ;;
  *)
    get_kbd_backlight
    ;;
esac
