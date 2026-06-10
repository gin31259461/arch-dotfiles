#!/usr/bin/env bash
# Refresh shell and notification state without restarting waybar.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=refresh-common.sh
source "$SCRIPT_DIR/refresh-common.sh"

refresh_close_clients rofi
refresh_reload_swaync

sleep 1
refresh_apply_rainbow_border
