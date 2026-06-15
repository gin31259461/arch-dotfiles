#!/usr/bin/env bash
# Cycles the window layout: dwindle → master → scrolling → dwindle

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

# On init: step one back in the cycle so the case block re-applies
# keybinds for the current layout without actually changing it.
if [[ "$1" == "init" ]]; then
  case $LAYOUT in
  "dwindle") LAYOUT="scrolling" ;;
  "master") LAYOUT="dwindle" ;;
  "scrolling") LAYOUT="master" ;;
  esac
fi

case $LAYOUT in
"dwindle")
  hypr_set_config "{ general = { layout = \"master\" } }"
  hypr_unbind "SUPER + J"
  hypr_unbind "SUPER + K"
  hypr_unbind "SUPER + O"
  hypr_bind "SUPER + J" "hl.dsp.layout(\"cyclenext\")"
  hypr_bind "SUPER + K" "hl.dsp.layout(\"cycleprev\")"
  notify_success "Window Layout" "Master" "$NOTIFY_FALLBACK_ICON" "window-layout"
  ;;
"master")
  hypr_set_config "{ general = { layout = \"scrolling\" } }"
  hypr_unbind "SUPER + J"
  hypr_unbind "SUPER + K"
  hypr_bind "SUPER + J" "hl.dsp.layout(\"focus d\")"
  hypr_bind "SUPER + K" "hl.dsp.layout(\"focus u\")"
  notify_success "Window Layout" "Scrolling" "$NOTIFY_FALLBACK_ICON" "window-layout"
  ;;
"scrolling")
  hypr_set_config "{ general = { layout = \"dwindle\" } }"
  hypr_unbind "SUPER + J"
  hypr_unbind "SUPER + K"
  hypr_bind "SUPER + J" "hl.dsp.window.cycle_next()"
  hypr_bind "SUPER + K" "hl.dsp.window.cycle_next({ next = false })"
  hypr_bind "SUPER + O" "hl.dsp.layout(\"togglesplit\")"
  notify_success "Window Layout" "Dwindle" "$NOTIFY_FALLBACK_ICON" "window-layout"
  ;;
esac
