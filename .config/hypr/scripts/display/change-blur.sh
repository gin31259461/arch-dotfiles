#!/usr/bin/env bash
# Adjusts window blur effect settings

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

STATE=$(hyprctl -j getoption decoration:blur:passes | jq ".int")

if [[ "${STATE}" == "2" ]]; then
  hypr_set_config "{ decoration = { blur = { size = 2, passes = 1 } } }"
  notify_info "Window Blur" "Reduced" "$(icon_img note.png)" "window-blur"
else
  hypr_set_config "{ decoration = { blur = { size = 5, passes = 2 } } }"
  notify_success "Window Blur" "Normal" "$(icon_img ja.png)" "window-blur"
fi
