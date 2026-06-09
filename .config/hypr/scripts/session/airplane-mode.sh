#!/usr/bin/env bash
# Controls airplane mode by toggling wifi on/off

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

notif="$(icon_img ja.png)"

# Check if any wireless device is blocked
wifi_blocked=$(rfkill list wifi | grep -o "Soft blocked: yes")

if [[ -n "$wifi_blocked" ]]; then
  rfkill unblock wifi
  notify_success "Airplane Mode" "Off" "$notif" "airplane-mode"
else
  rfkill block wifi
  notify_warn "Airplane Mode" "On" "$notif" "airplane-mode"
fi
