#!/usr/bin/env bash
# Rofi app launcher: drun mode with filebrowser, run, and window switching (SUPER D alternative).
# Uses ~/.config/rofi/config.rasi (theme selectable via SUPER CTRL R).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

rofi_close_existing
rofi -show drun -modi drun,filebrowser,run,window
