#!/usr/bin/env bash

set -euo pipefail

mode="${1:?mode is required}"
output="$(pacman -Qdtq 2>/dev/null || true)"
packages=()
if [[ -n "$output" ]]; then
  mapfile -t packages <<<"$output"
fi

case "$mode" in
  scan)
    if ((${#packages[@]} == 0)); then
      printf 'good\tno orphaned packages\n'
      printf 'pacman -Qdtq returned no packages.\n'
      exit 0
    fi
    printf 'bad\t%d orphaned package(s)\n' "${#packages[@]}"
    printf 'Review before removal. pacman will request transaction confirmation.\n'
    printf 'Keep a package: sudo pacman -D --asexplicit <package>\n'
    printf 'Packages:\n'
    printf '%s\n' "${packages[@]}"
    ;;
  run)
    if ((${#packages[@]} == 0)); then
      printf 'No orphaned packages found\n'
      exit 0
    fi
    printf 'Review orphan packages before removal:\n'
    printf '  %s\n' "${packages[@]}"
    sudo pacman -Rns "${packages[@]}"
    ;;
  *)
    printf 'Unsupported cleanup mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac
