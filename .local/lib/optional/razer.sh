#!/usr/bin/env bash

# more info:
# https://github.com/openrazer/openrazer/wiki/Configuring-OpenRazer

set_razer_group() {
  if ! groups "$USER" | grep -q "\bopenrazer\b"; then
    sudo gpasswd -a "$USER" openrazer
    note "Please log out and back in for group changes to take effect"
  fi
}

# troubleshooting: https://github.com/openrazer/openrazer/wiki/Troubleshooting
build_kernal_module() {
  note "Building Razer kernel module"
  local module
  module=$(find /usr/src -maxdepth 1 -type d -name 'openrazer-driver-*' -printf '%f\n' |
    sort -V |
    tail -n 1 |
    sed 's/\(openrazer-driver\)-\(.*\)/\1\/\2/')

  [[ -n "$module" ]] || {
    warn "No OpenRazer DKMS source found in /usr/src"
    return
  }

  sudo dkms install "$module"
  ok "Razer kernel module built and installed"
}

setup() {
  set_razer_group
  build_kernal_module

  systemctl --user enable openrazer-daemon.service
  ok "Setup Razer complete"
}
