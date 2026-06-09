#!/usr/bin/env bash
# Controls system volume and audio levels

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

iDIR="$SWAYNC_ICON_DIR"
sDIR="$SCRIPT_DIR/media"

get_volume() {
  local muted
  muted=$(pamixer --get-mute)
  if [[ "$muted" == "true" ]]; then
    echo "Muted"
    return
  fi
  local volume
  volume=$(pamixer --get-volume)
  if [[ "$volume" -eq 0 ]]; then
    echo "Muted"
  else
    echo "$volume %"
  fi
}

get_icon() {
  local muted
  muted=$(pamixer --get-mute)
  if [[ "$muted" == "true" ]]; then
    echo "$iDIR/volume-mute.png"
    return
  fi
  local current
  current=$(pamixer --get-volume)
  if [[ "$current" -le 30 ]]; then
    echo "$iDIR/volume-low.png"
  elif [[ "$current" -le 60 ]]; then
    echo "$iDIR/volume-mid.png"
  else
    echo "$iDIR/volume-high.png"
  fi
}

notify_user() {
  local muted level
  muted=$(pamixer --get-mute)
  level=$(pamixer --get-volume)
  if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
    notify_progress "Volume" "Muted" "" "$(get_icon)" "volume_notif"
  else
    notify_progress "Volume" "${level}%" "$level" "$(get_icon)" "volume_notif" \
      && "$sDIR/sounds.sh" --volume
  fi
}

inc_volume() {
  if [[ "$(pamixer --get-mute)" == "true" ]]; then
    toggle_mute
  else
    pamixer -i "$1" --allow-boost --set-limit 150 && notify_user
  fi
}

dec_volume() {
  if [[ "$(pamixer --get-mute)" == "true" ]]; then
    toggle_mute
  else
    pamixer -d "$1" && notify_user
  fi
}

toggle_mute() {
  local muted
  muted=$(pamixer --get-mute)
  if [[ "$muted" == "false" ]]; then
    pamixer -m && notify_progress "Volume" "Muted" "" "$iDIR/volume-mute.png" "volume_notif"
  elif [[ "$muted" == "true" ]]; then
    pamixer -u && notify_progress "Volume" "Switched on" "$(pamixer --get-volume)" "$(get_icon)" "volume_notif"
  fi
}

toggle_mic() {
  local muted
  muted=$(pamixer --default-source --get-mute)
  if [[ "$muted" == "false" ]]; then
    pamixer --default-source -m && notify_progress "Microphone" "Switched off" "" "$iDIR/microphone-mute.png" "mic_notif"
  elif [[ "$muted" == "true" ]]; then
    pamixer --default-source -u && notify_progress "Microphone" "Switched on" "$(pamixer --default-source --get-volume)" "$iDIR/microphone.png" "mic_notif"
  fi
}

get_mic_icon() {
  local muted current
  muted=$(pamixer --default-source --get-mute)
  current=$(pamixer --default-source --get-volume)
  if [[ "$muted" == "true" || "$current" -eq 0 ]]; then
    echo "$iDIR/microphone-mute.png"
  else
    echo "$iDIR/microphone.png"
  fi
}

get_mic_volume() {
  local muted
  muted=$(pamixer --default-source --get-mute)
  if [[ "$muted" == "true" ]]; then
    echo "Muted"
    return
  fi
  local volume
  volume=$(pamixer --default-source --get-volume)
  if [[ "$volume" -eq 0 ]]; then
    echo "Muted"
  else
    echo "$volume %"
  fi
}

notify_mic_user() {
  local muted level icon
  muted=$(pamixer --default-source --get-mute)
  level=$(pamixer --default-source --get-volume)
  if [[ "$muted" == "true" || "$level" -eq 0 ]]; then
    icon="$iDIR/microphone-mute.png"
    notify_progress "Microphone" "Muted" "" "$icon" "mic_notif"
  else
    icon="$iDIR/microphone.png"
    notify_progress "Microphone" "${level}%" "$level" "$icon" "mic_notif"
  fi
}

inc_mic_volume() {
  if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
    toggle_mic
  else
    pamixer --default-source -i 5 && notify_mic_user
  fi
}

dec_mic_volume() {
  if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
    toggle_mic
  else
    pamixer --default-source -d 5 && notify_mic_user
  fi
}

case "$1" in
  --get) get_volume ;;
  --inc) inc_volume 5 ;;
  --inc-precise) inc_volume 1 ;;
  --dec) dec_volume 5 ;;
  --dec-precise) dec_volume 1 ;;
  --toggle) toggle_mute ;;
  --toggle-mic) toggle_mic ;;
  --get-icon) get_icon ;;
  --get-mic-icon) get_mic_icon ;;
  --mic-inc) inc_mic_volume ;;
  --mic-dec) dec_mic_volume ;;
  *) get_volume ;;
esac
