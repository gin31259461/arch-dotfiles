#!/usr/bin/env bash
# Toggles game mode with optimized settings

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

notif="$(icon_img ja.png)"
scriptsDir="$SCRIPT_DIR"

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [[ "$HYPRGAMEMODE" == 1 ]]; then
  hypr_set_config "{ animations = { enabled = false }, decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 }, general = { gaps_in = 0, gaps_out = 0, border_size = 1 } }"
  hypr_eval 'hypr_game_mode_opacity = hl.window_rule({ name = "hypr-game-mode-opacity", match = { class = ".*" }, opacity = "1 override 1 override 1 override" })'
  notify_success "Game Mode" "Enabled" "$notif" "game-mode"
  sleep 0.1
  exit
else
  sleep 0.6
  hyprctl reload
  "${scriptsDir}/services/refresh.sh"
  notify_info "Game Mode" "Disabled" "$notif" "game-mode"
  exit
fi
