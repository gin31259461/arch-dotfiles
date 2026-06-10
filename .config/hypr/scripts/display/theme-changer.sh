#!/usr/bin/env bash
set -euo pipefail

# SPDX-FileCopyrightText: 2025-present Ahum Maitra theahummaitra@gmail.com
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Repository url : https://github.com/TheAhumMaitra/cautious-waddle

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

require() {
  command -v "$1" >/dev/null 2>&1 || {
    printf '%s\n' "Missing dependency: $1" >&2
    exit 127
  }
}

require wallust
require rofi

# Prompt for theme; guard -e on cancel
set +e
choice="$(wallust theme list \
  | sed -e '1d' -e 's/^- //' \
  | rofi -dmenu -i -p 'Select Global Theme')"
prompt_status=$?
set -e

# Exit cleanly on cancel or empty selection
if ((prompt_status != 0)) || [[ -z "${choice}" ]]; then
  exit 0
fi

# Record time before applying so we can wait for fresh template outputs
start_ts=$(date +%s)

# Apply the theme and report result
if wallust theme -- "${choice}"; then
  notify_success "Global Theme" "Selected: ${choice}" "$(icon_img ja.png)" "themechanger"

  # Ensure Ghostty directory exists so Wallust can write target even if Ghostty isn't installed
  mkdir -p "$HOME/.config/ghostty" || true

  targets=(
    "$HOME/.config/rofi/wallust/colors-rofi.rasi"
    "$HOME/.config/kitty/kitty-themes/01-Wallust.conf"
    "$HOME/.config/hypr/wallust/wallust-hyprland.conf"
    "$HOME/.config/ghostty/wallust.conf"
  )

  # Normalize Ghostty palette syntax in case upstream templates or older targets used ':'
  ghostty_conf="$HOME/.config/ghostty/wallust.conf"
  if [[ -f "$ghostty_conf" ]]; then
    sed -i -E 's/^(\s*palette\s*=\s*)([0-9]{1,2}):/\1\2=/' "$ghostty_conf" 2>/dev/null || true
  fi

  # Phase 1: wait for all targets to appear and be newer than start_ts
  ok=1
  for _ in $(seq 1 100); do
    ok=1
    for f in "${targets[@]}"; do
      [[ -s "$f" ]] || {
        ok=0
        break
      }
      mtime=$(stat -c %Y "$f" 2>/dev/null || echo 0)
      [[ "$mtime" -ge "$start_ts" ]] || {
        ok=0
        break
      }
    done
    [[ $ok -eq 1 ]] && break
    sleep 0.1
  done

  # Phase 2: stability check (avoid reading half-written files)
  if [[ $ok -eq 1 ]]; then
    for _ in 1 2 3; do
      sizes_a=()
      mtimes_a=()
      for f in "${targets[@]}"; do
        sizes_a+=("$(stat -c %s "$f" 2>/dev/null || echo 0)")
        mtimes_a+=("$(stat -c %Y "$f" 2>/dev/null || echo 0)")
      done
      sleep 0.15
      sizes_b=()
      mtimes_b=()
      for f in "${targets[@]}"; do
        sizes_b+=("$(stat -c %s "$f" 2>/dev/null || echo 0)")
        mtimes_b+=("$(stat -c %Y "$f" 2>/dev/null || echo 0)")
      done
      if [[ "${sizes_a[*]}" = "${sizes_b[*]}" ]] && [[ "${mtimes_a[*]}" = "${mtimes_b[*]}" ]]; then
        break
      fi
    done
  else
    sleep 0.5
  fi

  sleep 0.2

  # Normalize Rofi selection colors to use the palette's accent (color12)
  rofi_colors="$HOME/.config/rofi/wallust/colors-rofi.rasi"
  if [[ -f "$rofi_colors" ]]; then
    accent_hex=$(sed -n 's/^\s*color12:\s*\(#[0-9A-Fa-f]\{6\}\).*/\1/p' "$rofi_colors" | head -n1)
    [[ -z "$accent_hex" ]] && accent_hex=$(sed -n 's/^\s*color13:\s*\(#[0-9A-Fa-f]\{6\}\).*/\1/p' "$rofi_colors" | head -n1)
    if [[ -n "$accent_hex" ]]; then
      sed -i -E "s|^(\s*selected-normal-background:\s*).*$|\1$accent_hex;|" "$rofi_colors"
      sed -i -E "s|^(\s*selected-active-background:\s*).*$|\1$accent_hex;|" "$rofi_colors"
      sed -i -E "s|^(\s*selected-urgent-background:\s*).*$|\1$accent_hex;|" "$rofi_colors"
      sed -i -E "s|^(\s*selected-normal-foreground:\s*).*$|\1#000000;|" "$rofi_colors"
      sed -i -E "s|^(\s*selected-active-foreground:\s*).*$|\1#000000;|" "$rofi_colors"
      sed -i -E "s|^(\s*selected-urgent-foreground:\s*).*$|\1#000000;|" "$rofi_colors"
    fi
  fi

  # Reload Hyprland so new border colors from wallust-hyprland.conf take effect
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi

  # Refresh bars/menus after files are ready
  if [[ -x "$SCRIPT_DIR/services/refresh.sh" ]]; then
    "$SCRIPT_DIR/services/refresh.sh" >/dev/null 2>&1 || true
  fi

  # Ask kitty to reload its config
  if pidof kitty >/dev/null; then
    while IFS= read -r pid; do kill -SIGUSR1 "$pid" 2>/dev/null || true; done < <(pidof kitty | tr ' ' '\n')
  fi

  # Ask ghostty to reload its config
  if pidof ghostty >/dev/null; then
    while IFS= read -r pid; do kill -SIGUSR2 "$pid" 2>/dev/null || true; done < <(pidof ghostty | tr ' ' '\n')
  fi

else
  notify_error "Global Theme" "Failed to apply ${choice}."
  exit 1
fi
