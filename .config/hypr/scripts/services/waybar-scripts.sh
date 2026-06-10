#!/usr/bin/env bash
# Waybar click-handler helper.
# Usage: waybar-scripts.sh [--btop|--nvtop|--nmtui|--term|--files]

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

term="${TERMINAL:-kitty}"
files="${FILE_MANAGER:-thunar}"

run_terminal() {
  local -a terminal_cmd

  local IFS=' '
  read -r -a terminal_cmd <<<"$term"
  exec "${terminal_cmd[@]}" "$@"
}

run_file_manager() {
  local -a file_manager_cmd

  local IFS=' '
  read -r -a file_manager_cmd <<<"$files"
  exec "${file_manager_cmd[@]}"
}

case "${1:-}" in
  --btop) run_terminal --title btop -e btop ;;
  --nvtop) run_terminal --title nvtop -e nvtop ;;
  --nmtui) run_terminal -e nmtui ;;
  --term) run_terminal ;;
  --files)
    if [[ -z "$files" ]]; then
      notify_error "Waybar Scripts" "FILE_MANAGER is empty."
      exit 1
    fi
    run_file_manager
    ;;
  *)
    printf 'Usage: %s [--btop | --nvtop | --nmtui | --term | --files]\n' "$0" >&2
    exit 1
    ;;
esac
