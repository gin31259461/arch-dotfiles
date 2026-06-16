#!/usr/bin/env bash

setup() {
  note "Setting up SDDM (Simple Desktop Display Manager)"

  # Enable SDDM service
  sudo systemctl enable sddm.service
  ok "SDDM service enabled"

  cat <<EOF | sudo tee /etc/sddm.conf.d/autologin.conf >/dev/null
[Autologin]
User=$USER
Session=hyprland-uwsm
EOF

  cat <<EOF | sudo tee /usr/share/wayland-sessions/hyprland-uwsm.desktop >/dev/null
[Desktop Entry]
Name=Hyprland (uwsm)
Comment=Wayland compositor, uwsm session
Exec=uwsm start -- hyprland.desktop

# invalidates entry if uwsm is missing
TryExec=uwsm

DesktopNames=Hyprland
Type=Application
EOF

  # Provide guidance for configuration
  step "SDDM configuration tips:"
  step "  • System settings: Run 'systemsettings' and navigate to Startup and Shutdown → SDDM Login Screen"
  step "  • Config file: /etc/sddm.conf.d/"
  step "  • Theme directory: /usr/share/sddm/themes/"
  note "To activate SDDM now, restart the display manager:"
  note "  sudo systemctl restart display-manager"
  note "Or reboot to test the login screen"

  ok "SDDM setup complete"
}
