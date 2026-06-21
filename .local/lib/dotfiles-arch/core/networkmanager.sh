#!/usr/bin/env bash

NETWORK_MANAGER_CONFIG_DIR="/etc/NetworkManager/conf.d"

setup() {
  if [[ -d "$NETWORK_MANAGER_CONFIG_DIR" ]]; then
    if grep -q "dns=dnsmasq" "$NETWORK_MANAGER_CONFIG_DIR"/* 2>/dev/null; then
      ok "NetworkManager is already configured to use dnsmasq"
      return
    fi
  else
    note "Creating NetworkManager configuration directory at '$NETWORK_MANAGER_CONFIG_DIR'"
    sudo mkdir -p "$NETWORK_MANAGER_CONFIG_DIR"
  fi

  note "Configuring NetworkManager to use dnsmasq"

  cat <<EOF | sudo tee $NETWORK_MANAGER_CONFIG_DIR/main.conf >/dev/null
[main]
dns=dnsmasq
ignore-carrier=true

[connection]
wifi.powersave = 2
EOF

  note "NetworkManager configured to use dnsmasq"
  note "Configuring tailscale"

  cat <<EOF | sudo tee $NETWORK_MANAGER_CONFIG_DIR/99-tailscale.conf >/dev/null
[keyfile]
unmanaged-devices=interface-name:tailscale0
EOF

  note "Enable and start NetworkManager service"
  if systemctl is-active --quiet NetworkManager; then
    note "NetworkManager service is already running, restarting to apply new configuration"
    sudo systemctl restart NetworkManager
    ok "NetworkManager service restarted"
  else
    sudo systemctl enable NetworkManager --now
    ok "NetworkManager service started"
  fi

  note "Creating hotspot connection profile"

  if nmcli con show Arch-Hyprland &>/dev/null; then
    ok "Hotspot connection profile 'Arch-Hyprland' already exists"
    return
  fi

  nmcli con add con-name Arch-Hyprland ifname wlan0 type wifi ssid Arch-Hyprland
  nmcli con modify Arch-Hyprland wifi-sec.key-mgmt wpa-psk
  nmcli con modify Arch-Hyprland wifi-sec.psk "ilovearchlinux"
  nmcli con modify Arch-Hyprland wifi.mode ap
  nmcli con modify Arch-Hyprland ipv4.method shared
  nmcli con modify Arch-Hyprland ipv4.addresses 192.168.10.1/24
  nmcli con modify Arch-Hyprland ipv4.gateway 192.168.10.1

  ok "NetworkManager configured successfully"
}
