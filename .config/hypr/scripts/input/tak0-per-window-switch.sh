#!/usr/bin/env bash
# Switches keyboard layout per-window, restoring each window's last-used layout on focus

MAP_FILE="$HOME/.cache/kb_layout_per_window"
OPTIONS_FILE="$HOME/.config/hypr/lua/hyprconf/options.lua"
ICON="$HOME/.config/swaync/images/ja.png"
SCRIPT_NAME="$(basename "$0")"

touch "$MAP_FILE"

kb_source="$OPTIONS_FILE"
if ! grep -q 'kb_layout' "$kb_source"; then
  echo "Error: cannot find kb_layout in $kb_source" >&2
  exit 1
fi
kb_layouts=($(grep -m1 'kb_layout' "$kb_source" | cut -d '=' -f2 | tr -d '[:space:]",' | tr ',' ' '))
count=${#kb_layouts[@]}

get_win() {
  hyprctl activewindow -j | jq -r '.address // .id'
}

get_keyboards() {
  hyprctl devices -j | jq -r '.keyboards[].name'
}

save_map() {
  local win="$1" layout="$2"
  grep -v "^${win}:" "$MAP_FILE" > "$MAP_FILE.tmp"
  echo "${win}:${layout}" >> "$MAP_FILE.tmp"
  mv "$MAP_FILE.tmp" "$MAP_FILE"
}

load_map() {
  local win="$1"
  local entry
  entry=$(grep "^${win}:" "$MAP_FILE")
  [[ -n "$entry" ]] && echo "${entry#*:}" || echo "${kb_layouts[0]}"
}

do_switch() {
  local idx="$1"
  for kb in $(get_keyboards); do
    hyprctl switchxkblayout "$kb" "$idx" 2>/dev/null
  done
}

cmd_toggle() {
  local win
  win=$(get_win)
  [[ -z "$win" ]] && return
  local cur_layout
  cur_layout=$(load_map "$win")
  local i=0 next_idx
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$cur_layout" ]]; then
      i=$idx
      break
    fi
  done
  next_idx=$(( (i + 1) % count ))
  do_switch "$next_idx"
  save_map "$win" "${kb_layouts[next_idx]}"
  notify-send -u low -i "$ICON" "kb_layout: ${kb_layouts[next_idx]}"
}

cmd_restore() {
  local win
  win=$(get_win)
  [[ -z "$win" ]] && return
  local layout
  layout=$(load_map "$win")
  for idx in "${!kb_layouts[@]}"; do
    if [[ "${kb_layouts[idx]}" == "$layout" ]]; then
      do_switch "$idx"
      break
    fi
  done
}

subscribe() {
  local socket2="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  [[ -S "$socket2" ]] || { echo "Error: Hyprland socket not found." >&2; exit 1; }
  socat -u UNIX-CONNECT:"$socket2" - | while read -r line; do
    [[ "$line" =~ ^activewindow ]] && cmd_restore
  done
}

if ! pgrep -f "$SCRIPT_NAME.*--listener" >/dev/null; then
  subscribe --listener &
fi

case "$1" in
  toggle|"") cmd_toggle ;;
  *) echo "Usage: $SCRIPT_NAME [toggle]" >&2; exit 1 ;;
esac
