#!/usr/bin/env bash

set -euo pipefail

cleanup_format_bytes() {
  local bytes="${1:?bytes are required}"
  awk -v bytes="$bytes" '
    BEGIN {
      split("B KiB MiB GiB TiB", units, " ")
      value = bytes + 0
      unit = 1
      while (value >= 1024 && unit < 5) {
        value /= 1024
        unit++
      }
      if (unit == 1) printf "%d %s", value, units[unit]
      else printf "%.1f %s", value, units[unit]
    }
  '
}

cleanup_state_for_bytes() {
  local bytes="${1:?bytes are required}"
  if ((bytes == 0)); then
    printf 'good'
  elif ((bytes < 10 * 1024 * 1024)); then
    printf 'partial'
  else
    printf 'bad'
  fi
}

cleanup_directory_bytes() {
  local path="${1:?path is required}"
  if [[ ! -e "$path" ]]; then
    printf '0'
    return
  fi
  local output
  output="$(du -sb -- "$path" 2>/dev/null || true)"
  output="${output%%[[:space:]]*}"
  if [[ "$output" =~ ^[0-9]+$ ]]; then
    printf '%s' "$output"
    return
  fi
  return 1
}

cleanup_emit_size() {
  local bytes="${1:?bytes are required}"
  local summary="${2-}"
  local label="${3:?label is required}"
  local path="${4:-}"
  local formatted
  formatted="$(cleanup_format_bytes "$bytes")"
  printf '%s\t%s\n' "$(cleanup_state_for_bytes "$bytes")" "$formatted$summary"
  printf '%s: %s\n' "$label" "$formatted"
  if [[ -n "$path" ]]; then
    printf 'Path: %s\n' "$path"
  fi
}

cleanup_require_safe_path() {
  local path="${1:-}"
  if [[ -z "$path" || "$path" == / || "$path" == "$HOME" ]]; then
    printf 'Refusing unsafe cleanup path: %s\n' "$path" >&2
    return 1
  fi
}
