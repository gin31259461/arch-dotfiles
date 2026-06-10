#!/usr/bin/env bash
# Music player menu.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

music_dir="${MUSIC_DIR:-$HOME/Music}"
music_list="$ROFI_CONFIG_DIR/online_music.list"
rofi_theme="$ROFI_CONFIG_DIR/config-beats.rasi"
rofi_theme_menu="$ROFI_CONFIG_DIR/config-beats-menu.rasi"

notify_beats() {
  notify_info "${1:-Rofi Beats}" "${2:-}" "$(icon_symbol music.png)" "rofi-beats"
}

notify_beats_warn() {
  notify_warn "Rofi Beats" "$1" "$(icon_symbol music.png)" "rofi-beats"
}

notify_beats_error() {
  notify_error "Rofi Beats" "$1" "$(icon_img error.png)" "rofi-beats"
}

ensure_music_list() {
  mkdir -p "$(dirname "$music_list")"
  [[ -f "$music_list" ]] || : >"$music_list"
}

music_playing() {
  pgrep -x mpv >/dev/null
}

stop_music() {
  local mpv_pids=()
  local mpvpaper_pids=()
  local pid

  mapfile -t mpv_pids < <(pgrep -x mpv || true)
  ((${#mpv_pids[@]} == 0)) && return 0

  mapfile -t mpvpaper_pids < <(pgrep -f 'unique-wallpaper-process' || true)
  for pid in "${mpv_pids[@]}"; do
    if [[ " ${mpvpaper_pids[*]} " != *" $pid "* ]]; then
      kill "$pid" 2>/dev/null || true
    fi
  done

  notify_beats "Music stopped"
}

rofi_prompt() {
  local config="$1"
  local placeholder="$2"
  shift 2

  rofi_dmenu "$config" "" -theme-str "entry { placeholder: \"$placeholder\"; }" "$@"
}

select_from_lines() {
  local config="$1"
  local placeholder="$2"
  shift 2

  rofi_prompt "$config" "$placeholder" "$@"
}

load_local_music() {
  local files=()

  if [[ ! -d "$music_dir" ]]; then
    notify_beats_warn "Music directory not found: $music_dir"
    return 1
  fi

  mapfile -d '' -t files < <(
    find -L "$music_dir" -type f \
      \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.mp4' \) \
      -print0 | sort -zV
  )

  ((${#files[@]} > 0)) || {
    notify_beats_warn "No local music found in $music_dir"
    return 1
  }

  printf '%s\0' "${files[@]}"
}

play_local_music() {
  require_command mpv "Install mpv first." || exit 1

  local files=()
  local names=()
  local choice i

  mapfile -d '' -t files < <(load_local_music)
  ((${#files[@]} > 0)) || exit 0

  for i in "${!files[@]}"; do
    names+=("$(basename "${files[i]}")")
  done

  choice="$(printf '%s\n' "${names[@]}" | select_from_lines "$rofi_theme" "Choose local music")" || exit 0
  [[ -n "$choice" ]] || exit 0

  for i in "${!names[@]}"; do
    if [[ "${names[i]}" == "$choice" ]]; then
      music_playing && stop_music
      notify_beats "Now Playing:" "$choice"
      exec mpv --no-video --playlist-start="$i" --loop-playlist "${files[@]}"
    fi
  done

  notify_beats_error "Track not found: $choice"
  exit 1
}

shuffle_local_music() {
  require_command mpv "Install mpv first." || exit 1

  if [[ ! -d "$music_dir" ]]; then
    notify_beats_warn "Music directory not found: $music_dir"
    exit 0
  fi

  music_playing && stop_music
  notify_beats "Shuffle Play" "$music_dir"
  exec mpv --no-video --shuffle --loop-playlist "$music_dir"
}

online_titles() {
  awk -F'|' 'NF >= 2 && $1 != "" && $2 != "" { print $1 }' "$music_list" | sort -V
}

online_url_for_title() {
  local title="$1"

  awk -F'|' -v title="$title" '$1 == title { print $2; exit }' "$music_list"
}

play_online_music() {
  require_command mpv "Install mpv first." || exit 1

  local choice url

  if [[ ! -s "$music_list" ]]; then
    notify_beats_warn "No online music found. Add some with Manage Music."
    exit 0
  fi

  choice="$(online_titles | select_from_lines "$rofi_theme" "Choose online station")" || exit 0
  [[ -n "$choice" ]] || exit 0

  url="$(online_url_for_title "$choice")"
  if [[ -z "$url" ]]; then
    notify_beats_error "URL not found for $choice."
    exit 1
  fi

  music_playing && stop_music
  notify_beats "Now Playing:" "$choice"
  exec mpv --no-video --shuffle "$url"
}

add_online_music() {
  local name url

  name="$(printf '' | select_from_lines "$rofi_theme_menu" "Enter music title")" || return 0
  [[ -n "$name" ]] || return 0

  if [[ "$name" == *'|'* ]]; then
    notify_beats_error "Music titles cannot contain |"
    return 1
  fi

  url="$(printf '' | select_from_lines "$rofi_theme_menu" "Enter music URL")" || return 0
  [[ -n "$url" ]] || return 0

  printf '%s|%s\n' "$name" "$url" >>"$music_list"
  notify_beats "Added" "$name"
}

remove_online_music() {
  local entry temp_file

  if [[ ! -s "$music_list" ]]; then
    notify_beats_warn "No online music found."
    return 0
  fi

  entry="$(online_titles | select_from_lines "$rofi_theme_menu" "Select music to remove")" || return 0
  [[ -n "$entry" ]] || return 0

  temp_file="$(mktemp)"
  awk -F'|' -v entry="$entry" '$1 != entry' "$music_list" >"$temp_file"
  install -m 0644 "$temp_file" "$music_list"
  rm -f "$temp_file"

  notify_beats "Removed" "$entry"
}

view_online_music() {
  online_titles | select_from_lines "$rofi_theme_menu" "Online music list" >/dev/null || true
}

manage_music() {
  local sub_choice

  sub_choice="$(
    printf '%s\n' "Add Music" "Remove Music" "View List" \
      | select_from_lines "$rofi_theme_menu" "Manage music list"
  )" || return 0

  case "$sub_choice" in
    "Add Music") add_online_music ;;
    "Remove Music") remove_online_music ;;
    "View List") view_online_music ;;
  esac
}

main() {
  require_command rofi "Install rofi first." || exit 1
  ensure_music_list
  rofi_close_existing

  local choice
  choice="$(
    printf '%s\n' \
      "Play from Online Stations" \
      "Play from Music directory" \
      "Shuffle Play from Music directory" \
      "Stop Rofi Beats" \
      "Manage Music List" \
      | select_from_lines "$rofi_theme_menu" "Rofi Beats"
  )" || exit 0

  case "$choice" in
    "Play from Online Stations") play_online_music ;;
    "Play from Music directory") play_local_music ;;
    "Shuffle Play from Music directory") shuffle_local_music ;;
    "Stop Rofi Beats") music_playing && stop_music ;;
    "Manage Music List") manage_music ;;
  esac
}

main "$@"
