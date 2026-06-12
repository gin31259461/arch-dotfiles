#!/usr/bin/env bash

setup() {
  sudo systemctl enable --now docker.service

  if ! groups "$USER" | grep -q "\bdocker\b"; then
    sudo gpasswd -a "$USER" docker
    note "Please log out and back in for group changes to take effect"
  fi

  ok "Setup Docker complete"
}
