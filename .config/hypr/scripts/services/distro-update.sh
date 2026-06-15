#!/usr/bin/env bash
# Handles distribution-specific package updates

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

# Check for required tools (kitty)
require_command kitty "Kitty terminal not found. Please install Kitty terminal." || exit 1

distro_name=""

# Detect distribution and update accordingly
if command -v paru &>/dev/null; then
  kitty -T update -e paru -Syu
  distro_name="Arch-based system"
elif command -v yay &>/dev/null; then
  kitty -T update -e yay -Syu
  distro_name="Arch-based system"
elif command -v dnf &>/dev/null; then
  kitty -T update -e sudo dnf update --refresh -y
  distro_name="Fedora system"
elif command -v apt &>/dev/null; then
  kitty -T update -e bash -c "sudo apt update && sudo apt upgrade -y"
  distro_name="Debian/Ubuntu system"
elif command -v zypper &>/dev/null; then
  kitty -T update -e sudo zypper dup -y
  distro_name="openSUSE system"
else
  notify_error "Unsupported System" "This script does not support your distribution."
  exit 1
fi

notify_success "System Update" "$distro_name has been updated." "$NOTIFY_FALLBACK_ICON" "system-update"
