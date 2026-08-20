#!/usr/bin/env bash

set -euo pipefail

sunshine="$(command -v sunshine || true)"
if [[ -z "$sunshine" ]]; then
  printf 'Sunshine executable not found\n'
  exit 0
fi
sunshine="$(readlink -f "$sunshine")"
if ! getcap "$sunshine" | grep -Fq cap_sys_admin; then
  sudo setcap cap_sys_admin+p "$sunshine"
fi
systemctl --user enable app-dev.lizardbyte.app.Sunshine.service
