#!/usr/bin/env bash
# Initializes keyboard bindings for layout switching
# Initialize J/K keybinds so they always cycle windows globally (no layout-specific behavior)
# This avoids double-actions when layouts change.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Always reset and bind SUPER+J/K the same way on startup
hypr_unbind "SUPER + J" || true
hypr_unbind "SUPER + K" || true

# Cycle windows globally: J = next, K = previous
hypr_bind "SUPER + J" "hl.dsp.window.cycle_next()"
hypr_bind "SUPER + K" "hl.dsp.window.cycle_next({ next = false })"
