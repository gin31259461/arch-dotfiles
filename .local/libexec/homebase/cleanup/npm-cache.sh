#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mode="${1:?mode is required}"

case "$mode" in
  scan)
    root="$(npm config get cache)"
    path="$root/_cacache"
    bytes="$(cleanup_directory_bytes "$path")"
    cleanup_emit_size "$bytes" "" "npm content-addressable cache" "$path"
    printf 'npm cache root: %s\n' "$root"
    ;;
  run)
    npm cache clean --force
    ;;
  *)
    printf 'Unsupported cleanup mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac
