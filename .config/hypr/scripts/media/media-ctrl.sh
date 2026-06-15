#!/usr/bin/env bash
# Controls media playback and player functions

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

music_icon="$NOTIFY_FALLBACK_ICON"

# Play the next track
play_next() {
  playerctl next
  show_music_notification
}

# Play the previous track
play_previous() {
  playerctl previous
  show_music_notification
}

# Toggle play/pause
toggle_play_pause() {
  playerctl play-pause
  sleep 0.1
  show_music_notification
}

# Stop playback
stop_playback() {
  playerctl stop
  notify_info "Playback" "Stopped" "$music_icon" "media-playback"
}

# Display notification with song information
show_music_notification() {
  status=$(playerctl status)
  if [[ "$status" == "Playing" ]]; then
    song_title=$(playerctl metadata title)
    song_artist=$(playerctl metadata artist)
    notify_success "Now Playing" "$song_title by $song_artist" "$music_icon" "media-playback"
  elif [[ "$status" == "Paused" ]]; then
    notify_info "Playback" "Paused" "$music_icon" "media-playback"
  fi
}

# Get media control action from command line argument
case "$1" in
"--nxt")
  play_next
  ;;
"--prv")
  play_previous
  ;;
"--pause")
  toggle_play_pause
  ;;
"--stop")
  stop_playback
  ;;
*)
  echo "Usage: $0 [--nxt|--prv|--pause|--stop]"
  exit 1
  ;;
esac
