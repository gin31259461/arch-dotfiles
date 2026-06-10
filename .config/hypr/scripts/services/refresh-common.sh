#!/usr/bin/env bash
# Shared helpers for refresh entrypoints.

_refresh_common_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../lib/common.sh
source "$_refresh_common_dir/../lib/common.sh"
unset _refresh_common_dir

refresh_close_clients() {
  kill_by_name "$@"
}

refresh_cleanup_waybar_cava() {
  noctalia_shell_manages waybar && return 0

  pkill -f 'waybar-cava\..*\.conf' 2>/dev/null || true
}

refresh_restart_waybar() {
  noctalia_shell_manages waybar && return 0
  command_exists waybar || return 0

  local manage_with_systemd=0
  if command_exists systemctl; then
    if systemctl --user --quiet is-active waybar.service 2>/dev/null \
      || systemctl --user --quiet is-enabled waybar.service 2>/dev/null; then
      manage_with_systemd=1
    fi
  fi

  if [[ "$manage_with_systemd" -eq 1 ]]; then
    systemctl --user stop waybar.service >/dev/null 2>&1 || true
  fi

  kill_by_name waybar .waybar-wrapped
  sleep 0.2

  if pgrep -x waybar >/dev/null 2>&1 \
    || pgrep -x '.waybar-wrapped' >/dev/null 2>&1; then
    pkill -9 -x waybar >/dev/null 2>&1 || true
    pkill -9 -x '.waybar-wrapped' >/dev/null 2>&1 || true
  fi

  sleep 0.2
  if [[ "$manage_with_systemd" -eq 1 ]]; then
    if ! systemctl --user start waybar.service >/dev/null 2>&1; then
      waybar >/dev/null 2>&1 &
    fi
  else
    waybar >/dev/null 2>&1 &
  fi
}

refresh_restart_swaync() {
  if command_exists swaync; then
    kill_by_name swaync
    sleep 0.3
    swaync >/dev/null 2>&1 &
  fi

  refresh_reload_swaync
}

refresh_reload_swaync() {
  if command_exists swaync-client; then
    swaync-client --reload-config >/dev/null 2>&1 || true
  fi
}

refresh_apply_rainbow_border() {
  local rainbow_script="$HYPR_SCRIPTS_DIR/display/rainbow-border.sh"

  if rainbow_border_enabled && [[ -x "$rainbow_script" ]]; then
    "$rainbow_script" >/dev/null 2>&1 &
  fi
}
