#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

destination=/etc/systemd/system/getty@tty1.service.d/override.conf
target="$(setup_root_path "$destination")"
if [[ -f "$target" ]] && grep -Fq -- "--autologin ${USER:?USER is required}" "$target"; then
  printf 'TTY1 autologin already configured\n'
  exit 0
fi

setup_install_root_file "$destination" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${USER} --noclear %I \$TERM
EOF
