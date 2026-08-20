#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

setup_install_root_file /etc/NetworkManager/conf.d/main.conf <<'EOF'
[main]
dns=dnsmasq
ignore-carrier=true

[connection]
wifi.powersave = 2
EOF

setup_install_root_file /etc/NetworkManager/conf.d/99-tailscale.conf <<'EOF'
[keyfile]
unmanaged-devices=interface-name:tailscale0
EOF

setup_install_root_file /etc/sysctl.d/99-homebase.conf <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

if [[ -z "${HOMEBASE_SETUP_ROOT:-}" ]]; then
  if systemctl is-active --quiet NetworkManager; then
    sudo systemctl restart NetworkManager
  else
    sudo systemctl enable NetworkManager --now
  fi
  sudo sysctl --system
fi

if nmcli con show Arch-Hyprland >/dev/null 2>&1; then
  printf 'Hotspot connection profile already exists\n'
  exit 0
fi

psk="$(head -c 24 /dev/urandom | base64 | tr -d '=+/\n' | cut -c1-24)"
nmcli con add con-name Arch-Hyprland ifname wlan0 type wifi ssid Arch-Hyprland
nmcli con modify Arch-Hyprland wifi.band bg wifi.channel 6 wifi.mode ap
nmcli con modify Arch-Hyprland wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$psk" 802-11-wireless-security.pmf 1
nmcli con modify Arch-Hyprland ipv4.addresses 192.168.10.1/24 ipv4.method shared ipv4.never-default yes
nmcli con modify Arch-Hyprland ipv6.method shared ipv6.addr-gen-mode default
nmcli con modify Arch-Hyprland 802-11-wireless-security.proto rsn 802-11-wireless-security.pairwise ccmp 802-11-wireless-security.group ccmp
printf 'Generated a unique hotspot PSK; inspect it through nmcli when needed\n'
