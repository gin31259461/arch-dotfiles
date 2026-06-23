#!/usr/bin/env bash

NETWORK_MANAGER_CONFIG_DIR="/etc/NetworkManager/conf.d"

setup() {
  if ! [[ -d "$NETWORK_MANAGER_CONFIG_DIR" ]]; then
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

  note "Configuring sysctl settings"

  cat <<EOF | sudo tee /etc/sysctl.d/99-sysctl.conf >/dev/null
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

  note "Applying sysctl settings"
  sudo sysctl --system >/dev/null
  note "Sysctl settings applied successfully"

  note "Creating hotspot connection profile"

  if nmcli con show Arch-Hyprland &>/dev/null; then
    ok "Hotspot connection profile 'Arch-Hyprland' already exists"
    return
  fi

  nmcli con add con-name Arch-Hyprland ifname wlan0 type wifi ssid Arch-Hyprland

  # [wifi]
  nmcli con modify Arch-Hyprland \
    wifi.band bg \
    wifi.channel 6 \
    wifi.mode ap

  # [wifi-security]
  nmcli con modify Arch-Hyprland \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "ilovearchlinux" \
    802-11-wireless-security.pmf 1

  # [ipv4]
  nmcli con modify Arch-Hyprland \
    ipv4.addresses 192.168.10.1/24 \
    ipv4.method shared \
    ipv4.never-default yes

  # [ipv6]
  nmcli con modify Arch-Hyprland \
    ipv6.method shared \
    ipv6.addr-gen-mode default

  # strict security settings
  # nmcli con modify Arch-Hyprland \
  #   802-11-wireless-security.proto rsn \
  #   802-11-wireless-security.pairwise ccmp \
  #   802-11-wireless-security.group ccmp \

  note "Hotspot connection profile 'Arch-Hyprland' created successfully"
  note "You'll need to check Wi-Fi adapter name with 'ip a'"
  note "Then change 'wlan0' to your adapter name in the above nmcli commands"
  note "E.g. 'nmcli con modify Arch-Hyprland ifname <your_adapter_name>'"
  note "Use 'nmcli con up Arch-Hyprland' to activate the hotspot connection"

  ok "NetworkManager setup completed successfully"
}
