#!/usr/bin/env bash

set -euo pipefail

setup_root_path() {
  printf '%s%s' "${HOMEBASE_SETUP_ROOT:-}" "$1"
}

setup_install_root_file() {
  local destination="$1"
  local target
  local temporary
  target="$(setup_root_path "$destination")"
  temporary="$(mktemp)"
  trap 'rm -f "$temporary"' RETURN
  cat >"$temporary"
  if [[ -n "${HOMEBASE_SETUP_ROOT:-}" ]]; then
    install -Dm644 "$temporary" "$target"
  else
    sudo install -Dm644 "$temporary" "$target"
  fi
}

setup_user_in_group() {
  local user="$1"
  local group="$2"
  groups "$user" | tr ' ' '\n' | grep -Fxq "$group"
}

setup_add_user_to_group() {
  local user="$1"
  local group="$2"
  if setup_user_in_group "$user" "$group"; then
    return
  fi
  sudo gpasswd -a "$user" "$group"
  printf 'Log out and back in for %s group changes\n' "$group"
}
