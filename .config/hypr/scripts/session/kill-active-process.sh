#!/usr/bin/env bash
# Terminates the currently active window process

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

# Get id of an active window
active_pid=$(hyprctl -j activewindow | jq -r '.pid')

if [[ -z "$active_pid" || ! "$active_pid" =~ ^[0-9]+$ ]]; then
  notify_error "Kill Active Window" "No active window PID found." "" "kill-active-window"
  exit 1
fi

# Close active window
kill "$active_pid"
