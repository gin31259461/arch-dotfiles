#!/usr/bin/env bash
# Compatibility entrypoint for the rofi theme selector.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

exec "$SCRIPT_DIR/rofi/rofi-theme-selector.sh" "$@"
