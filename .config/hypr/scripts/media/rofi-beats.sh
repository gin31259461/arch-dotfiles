#!/usr/bin/env bash
# Music player interface via Rofi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

mDIR="$HOME/Music/"
iDIR="$SWAYNC_ICON_DIR"
rofi_theme="$ROFI_CONFIG_DIR/config-rofi-Beats.rasi"
rofi_theme_menu="$ROFI_CONFIG_DIR/config-rofi-Beats-menu.rasi"
music_list="$ROFI_CONFIG_DIR/online_music.list"

mkdir -p "$(dirname "$music_list")"
[[ -f "$music_list" ]] || touch "$music_list"

# Send notification
notification() {
  notify_info "${1:-Rofi Beats}" "${2:-}" "$iDIR/music.png" "rofi-beats"
}

# Check if mpv is currently playing
music_playing() { pgrep -x "mpv" >/dev/null; }

# Stop all mpv processes except mpvpaper
stop_music() {
  mapfile -t mpv_pids < <(pgrep -x mpv)
  [[ ${#mpv_pids[@]} -eq 0 ]] && return
  mapfile -t mpvpaper_pids < <(pgrep -f 'unique-wallpaper-process')
  for pid in "${mpv_pids[@]}"; do
    if [[ " ${mpvpaper_pids[*]} " != *" ${pid} "* ]]; then
      kill -9 "$pid" || true
    fi
  done
  notification "Music stopped"
}

# Populate local music file list
populate_local_music() {
  local_music=()
  filenames=()
  while IFS= read -r file; do
    local_music+=("$file")
    filenames+=("$(basename "$file")")
  done < <(find -L "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))
}

# Play selected local music file
play_local_music() {
  populate_local_music
  choice=$(printf "%s\n" "${filenames[@]}" | rofi -i -dmenu -config "$rofi_theme" \
    -theme-str 'entry { placeholder: "Choose Local Music"; }')
  [[ -z "$choice" ]] && exit 1
  for ((i = 0; i < "${#filenames[@]}"; ++i)); do
    if [[ "${filenames[$i]}" == "$choice" ]]; then
      music_playing && stop_music
      notification "Now Playing:" "$choice"
      mpv --no-video --playlist-start="$i" --loop-playlist "${local_music[@]}"
      break
    fi
  done
}

# Shuffle and play all local music
shuffle_local_music() {
  music_playing && stop_music
  notification "Shuffle Play local music"
  mpv --no-video --shuffle --loop-playlist "$mDIR"
}

# Play selected online music
play_online_music() {
  if [[ ! -s "$music_list" ]]; then
    notify_warn "Rofi Beats" "No online music found. Add some with Manage Music." "$iDIR/music.png" "rofi-beats"
    exit 0
  fi
  choice=$(awk -F'|' '{print $1}' "$music_list" | sort | rofi -i -dmenu -config "$rofi_theme" \
    -theme-str 'entry { placeholder: "Choose Online Station"; }')
  [[ -z "$choice" ]] && exit 1
  link=$(awk -F'|' -v name="$choice" '$1 == name {print $2; exit}' "$music_list")
  [[ -z "$link" ]] && {
    notify_error "Rofi Beats" "URL not found for $choice." "$iDIR/music.png" "rofi-beats"
    exit 1
  }
  music_playing && stop_music
  notification "Now Playing:" "$choice"
  mpv --no-video --shuffle "$link"
}

# Manage online music list (add, remove, view)
manage_music() {
  sub_choice=$(printf "Add Music\nRemove Music\nView List" | rofi -dmenu \
    -config "$rofi_theme_menu" \
    -theme-str 'entry { placeholder: "🛠️ Manage Music List"; }')

  case "$sub_choice" in
    "Add Music")
      name=$(rofi -dmenu -lines 0 -config "$rofi_theme_menu" \
        -theme-str 'entry { placeholder: "🎼 Enter Music Title"; }')
      [[ -z "$name" ]] && return
      url=$(rofi -dmenu -lines 0 -config "$rofi_theme_menu" \
        -theme-str 'entry { placeholder: "🔗 Enter Music URL"; }')
      [[ -z "$url" ]] && return
      echo "$name|$url" >>"$music_list"
      notification "Added" "$name"
      ;;
    "Remove Music")
      entry=$(awk -F'|' '{print $1}' "$music_list" | rofi -dmenu -config "$rofi_theme_menu" \
        -theme-str 'entry { placeholder: "🗑️ Select Music to Remove"; }')
      [[ -z "$entry" ]] && return
      grep -vF "$entry" "$music_list" >"$music_list.tmp" && mv "$music_list.tmp" "$music_list"
      notification "Removed" "$entry"
      ;;
    "View List")
      # Show only titles, not URLs
      awk -F'|' '{print $1}' "$music_list" | rofi -dmenu -config "$rofi_theme_menu" \
        -theme-str 'entry { placeholder: "📜 Online Music List"; }' >/dev/null
      ;;
  esac
}

# Main menu
user_choice=$(printf "%s\n" \
  "Play from Online Stations" \
  "Play from Music directory" \
  "Shuffle Play from Music directory" \
  "Stop RofiBeats" \
  "Manage Music List" \
  | rofi -dmenu -config "$rofi_theme_menu" \
    -theme-str 'entry { placeholder: "🎧 RofiBeats Menu"; }')

case "$user_choice" in
  "Play from Online Stations") play_online_music ;;
  "Play from Music directory") play_local_music ;;
  "Shuffle Play from Music directory") shuffle_local_music ;;
  "Stop RofiBeats") music_playing && stop_music ;;
  "Manage Music List") manage_music ;;
esac
