#!/usr/bin/env bash
# Captures screenshots with various options

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

time=$(date "+%d-%b_%H-%M-%S")
PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
dir="$PICTURES_DIR/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

sDIR="$SCRIPT_DIR/media"

active_window_class=$(hyprctl -j activewindow | jq -r '(.class)')
active_window_file="Screenshot_${time}_${active_window_class}.png"
active_window_path="${dir}/${active_window_file}"

notify_view() {
  if [[ "$1" == "active" ]]; then
    if [[ -e "${active_window_path}" ]]; then
      "${sDIR}/sounds.sh" --screenshot
      resp=$(notify_action "Screenshot" "${active_window_class} saved." "$NOTIFY_FALLBACK_ICON" "shot-notify" 10000 action1=Open action2=Delete)
      case "$resp" in
      action1) xdg-open "${active_window_path}" & ;;
      action2) rm "${active_window_path}" & ;;
      esac
    else
      notify_warn "Screenshot" "${active_window_class} not saved." "$NOTIFY_FALLBACK_ICON" "shot-notify"
      "${sDIR}/sounds.sh" --error
    fi

  elif [[ "$1" == "swappy" ]]; then
    "${sDIR}/sounds.sh" --screenshot
    resp=$(notify_action "Screenshot" "Captured by Swappy." "$NOTIFY_FALLBACK_ICON" "shot-notify" 10000 action1=Open action2=Delete)
    case "$resp" in
    action1) swappy -f "$2" ;;
    action2) rm "$2" ;;
    esac

  else
    local check_file="${dir}/${file}"
    if [[ -e "$check_file" ]]; then
      "${sDIR}/sounds.sh" --screenshot
      resp=$(notify_action "Screenshot" "Saved." "$NOTIFY_FALLBACK_ICON" "shot-notify" 10000 action1=Open action2=Delete)
      case "$resp" in
      action1) xdg-open "${check_file}" & ;;
      action2) rm "${check_file}" & ;;
      esac
    else
      notify_warn "Screenshot" "Not saved." "$NOTIFY_FALLBACK_ICON" "shot-notify"
      "${sDIR}/sounds.sh" --error
    fi
  fi
}

countdown() {
  for sec in $(seq "$1" -1 1); do
    notify_message "Screenshot" "Capturing in ${sec}s" "$NOTIFY_FALLBACK_ICON" low "shot-notify" 1000
    sleep 1
  done
}

shotnow() {
  cd "${dir}" && grim - | tee "$file" | wl-copy
  sleep 2
  notify_view
}

shot5() {
  countdown '5'
  sleep 1 && cd "${dir}" && grim - | tee "$file" | wl-copy
  sleep 1
  notify_view
}

shot10() {
  countdown '10'
  sleep 1 && cd "${dir}" && grim - | tee "$file" | wl-copy
  notify_view
}

shotwin() {
  local w_pos w_size
  w_pos=$(hyprctl activewindow | grep 'at:' | cut -d':' -f2 | tr -d ' ' | tail -n1)
  w_size=$(hyprctl activewindow | grep 'size:' | cut -d':' -f2 | tr -d ' ' | tail -n1 | sed 's/,/x/g')
  cd "${dir}" && grim -g "$w_pos $w_size" - | tee "$file" | wl-copy
  notify_view
}

shotarea() {
  local tmpfile
  tmpfile=$(mktemp)
  grim -g "$(slurp)" - >"$tmpfile" || {
    rm "$tmpfile"
    return
  }

  if [[ -s "$tmpfile" ]]; then
    wl-copy <"$tmpfile"
    mv "$tmpfile" "$dir/$file"
  fi
  notify_view
}

shotactive() {
  active_window_class=$(hyprctl -j activewindow | jq -r '(.class)')
  active_window_file="Screenshot_${time}_${active_window_class}.png"
  active_window_path="${dir}/${active_window_file}"

  hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - "${active_window_path}"
  sleep 1
  notify_view "active"
}

shotswappy() {
  local tmpfile
  tmpfile=$(mktemp)
  grim -g "$(slurp)" - >"$tmpfile" || {
    rm "$tmpfile"
    return
  }

  if [[ -s "$tmpfile" ]]; then
    wl-copy <"$tmpfile"
    notify_view "swappy" "$tmpfile"
  fi
}

if [[ ! -d "$dir" ]]; then
  mkdir -p "$dir"
fi

if [[ "$1" == "--now" ]]; then
  shotnow
elif [[ "$1" == "--in5" ]]; then
  shot5
elif [[ "$1" == "--in10" ]]; then
  shot10
elif [[ "$1" == "--win" ]]; then
  shotwin
elif [[ "$1" == "--area" ]]; then
  shotarea
elif [[ "$1" == "--active" ]]; then
  shotactive
elif [[ "$1" == "--swappy" ]]; then
  shotswappy
else
  echo -e "Available Options : --now --in5 --in10 --win --area --active --swappy"
fi

exit 0
