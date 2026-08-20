#!/usr/bin/env bash

set -euo pipefail

units=(
  hyprpolkitagent.service
  vicinae.service
  keepassxc.service
  noctalia.service
  quickshell-overview.service
  polychromatic-tray.service
  remmina-applet.service
  tailscale-systray.service
  vesktop.service
)
start_when_graphical=(true true false false false false false false false)

systemctl --user daemon-reload
graphical=false
if systemctl --user is-active --quiet graphical-session.target; then
  graphical=true
fi

missing=()
for index in "${!units[@]}"; do
  unit="${units[$index]}"
  if ! systemctl --user cat "$unit" >/dev/null 2>&1; then
    missing+=("$unit")
    continue
  fi
  args=(--user enable)
  if [[ "$graphical" == true && "${start_when_graphical[$index]}" == true ]]; then
    args+=(--now)
  fi
  systemctl "${args[@]}" "$unit"
  if [[ "$graphical" == true && "${start_when_graphical[$index]}" == true ]]; then
    systemctl --user is-active --quiet "$unit"
  fi
done

if ((${#missing[@]} > 0)); then
  printf 'Required user services unavailable: %s\n' "${missing[*]}" >&2
  exit 1
fi
