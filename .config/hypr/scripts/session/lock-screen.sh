#!/usr/bin/env bash
# Handles screen locking functionality

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"

# Ensure weather cache is up-to-date before locking
"$SCRIPT_DIR/services/weather-wrap.sh" >/dev/null 2>&1

loginctl lock-session
