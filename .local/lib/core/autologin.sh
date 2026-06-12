#!/usr/bin/env bash

GETTY_TTY1_DIR="/etc/systemd/system/getty@tty1.service.d"

remove_autologin() {
  note "Removing autologin configuration for user '$USER' on tty1"

  OVERRIDE_PATH="$GETTY_TTY1_DIR/override.conf"
  if [ -f "$OVERRIDE_PATH" ]; then
    sudo rm "$OVERRIDE_PATH"
  fi

  ok "Autologin configuration removed"
}

setup() {
  if [[ -f "$GETTY_TTY1_DIR/override.conf" ]]; then
    ok "Autologin already configured for '$USER' on tty1"
    return
  fi

  note "Setting up autologin for user '$USER' on tty1"

  if [[ ! -d "$GETTY_TTY1_DIR" ]]; then
    sudo mkdir -p "$GETTY_TTY1_DIR"
  fi

  cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf >/dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF

  ok "Autologin configured"
}
