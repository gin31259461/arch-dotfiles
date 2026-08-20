#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

cache=/var/cache/pacman/pkg
mode="${1:?mode is required}"

case "$mode" in
  scan)
    mapfile -t candidates < <(paccache -dq -c "$cache")
    reclaimable=0
    for candidate in "${candidates[@]}"; do
      if [[ -f "$candidate" ]]; then
        size="$(stat -c %s -- "$candidate" 2>/dev/null || printf '0')"
        ((reclaimable += size))
      fi
    done
    total="$(cleanup_directory_bytes "$cache")"
    printf '%s\t%s reclaimable\n' \
      "$(cleanup_state_for_bytes "$reclaimable")" \
      "$(cleanup_format_bytes "$reclaimable")"
    printf 'Total cache: %s\n' "$(cleanup_format_bytes "$total")"
    printf 'Path: %s\n' "$cache"
    ;;
  run)
    sudo paccache -r
    ;;
  *)
    printf 'Unsupported cleanup mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac
