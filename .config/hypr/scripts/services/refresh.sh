#!/usr/bin/env bash
# Refresh transient menus and optional visual effects.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=refresh-common.sh
source "$SCRIPT_DIR/refresh-common.sh"

refresh_close_clients rofi

sleep 1
refresh_apply_rainbow_border
