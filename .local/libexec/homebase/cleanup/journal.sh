#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mode="${1:?mode is required}"
target=$((100 * 1024 * 1024))

case "$mode" in
  scan)
    output="$(journalctl --disk-usage)"
    token="$(grep -Eo '[0-9]+([.][0-9]+)?[KMGT]' <<<"$output" | tail -n 1 || true)"
    if [[ -z "$token" ]]; then
      printf 'partial\tjournal size reported\n%s\n' "$output"
      exit 0
    fi
    total="$(awk -v token="$token" '
      BEGIN {
        unit = substr(token, length(token), 1)
        value = substr(token, 1, length(token) - 1) + 0
        multiplier = 1
        if (unit == "K") multiplier = 1024
        else if (unit == "M") multiplier = 1024 ^ 2
        else if (unit == "G") multiplier = 1024 ^ 3
        else if (unit == "T") multiplier = 1024 ^ 4
        printf "%.0f", value * multiplier
      }
    ')"
    reclaimable=$((total > target ? total - target : 0))
    printf '%s\t%s over %s target\n' \
      "$(cleanup_state_for_bytes "$reclaimable")" \
      "$(cleanup_format_bytes "$reclaimable")" \
      "$(cleanup_format_bytes "$target")"
    printf 'Total journal usage: %s\n' "$(cleanup_format_bytes "$total")"
    printf '%s\n' "$output"
    ;;
  run)
    sudo journalctl --vacuum-size=100M
    ;;
  *)
    printf 'Unsupported cleanup mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac
