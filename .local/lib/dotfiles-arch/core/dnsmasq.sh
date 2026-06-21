#!/usr/bin/env bash

setup() {
  note "Enable and start dnsmasq service"

  if systemctl is-active --quiet dnsmasq; then
    note "dnsmasq service is already running, restarting to apply new configuration"
    sudo systemctl restart dnsmasq
    ok "dnsmasq service restarted"
  else
    sudo systemctl enable dnsmasq --now
    ok "dnsmasq service started"
  fi

  ok "dnsmasq setup completed successfully"
}
