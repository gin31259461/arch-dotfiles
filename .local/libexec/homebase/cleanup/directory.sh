#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mode="${1:?mode is required}"
path="${2:?path is required}"
label="${3:?label is required}"

case "$mode" in
  scan)
    bytes="$(cleanup_directory_bytes "$path")"
    cleanup_emit_size "$bytes" "" "$label" "$path"
    ;;
  run)
    cleanup_require_safe_path "$path"
    rm -rf -- "$path"
    ;;
  *)
    printf 'Unsupported cleanup mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac
