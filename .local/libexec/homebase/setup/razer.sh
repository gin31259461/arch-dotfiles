#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

setup_add_user_to_group "${USER:?USER is required}" openrazer
module="$(find /usr/src -mindepth 1 -maxdepth 1 -type d -name 'openrazer-driver-*' -printf '%f\n' 2>/dev/null | sort -V | tail -n 1)"
if [[ -n "$module" ]]; then
  sudo dkms install "openrazer-driver/${module#openrazer-driver-}"
else
  printf 'No OpenRazer DKMS source found in /usr/src\n'
fi
systemctl --user enable openrazer-daemon.service
