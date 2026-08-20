#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

config="$(setup_root_path /etc/mkinitcpio.conf)"
if ! lsmod | awk '{print tolower($1)}' | grep -Fxq amdgpu; then
  printf 'amdgpu is not active; leaving %s unchanged\n' "$config"
  exit 0
fi

if grep -Eq '^[[:space:]]*MODULES=\(usbhid xhci_pci amdgpu\)[[:space:]]*$' "$config"; then
  printf 'mkinitcpio modules already configured for amdgpu\n'
  exit 0
fi

temporary="$(mktemp)"
trap 'rm -f "$temporary"' EXIT
awk '
  BEGIN { replaced = 0 }
  /^[[:space:]]*MODULES=/ {
    print "MODULES=(usbhid xhci_pci amdgpu)"
    replaced = 1
    next
  }
  { print }
  END {
    if (!replaced) print "MODULES=(usbhid xhci_pci amdgpu)"
  }
' "$config" >"$temporary"

if [[ -n "${HOMEBASE_SETUP_ROOT:-}" ]]; then
  install -Dm644 "$temporary" "$config"
else
  sudo install -Dm644 "$temporary" /etc/mkinitcpio.conf
  sudo mkinitcpio -P
fi
