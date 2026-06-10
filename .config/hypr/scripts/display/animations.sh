#!/usr/bin/env bash
# Compatibility entrypoint for the animation profile selector.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec "$SCRIPT_DIR/profile-selector/animation" "$@"
