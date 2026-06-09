#!/usr/bin/env bash
# Selects a monitor profile and writes it to lua/user/monitors.lua.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

PROFILE_DIR="$HYPR_CONFIG_DIR/monitor-profiles"
USER_DIR="$HYPR_CONFIG_DIR/lua/user"
ACTIVE_PROFILE="$USER_DIR/monitors.lua"
ROFI_THEME="$ROFI_CONFIG_DIR/config-Monitors.rasi"
MENU_MESSAGE="Choose a monitor profile"

profile_name() {
  basename "$1" .lua
}

current_profile_name() {
  local profile

  [[ -f "$ACTIVE_PROFILE" ]] || return 0
  while IFS= read -r -d '' profile; do
    if cmp -s "$profile" "$ACTIVE_PROFILE"; then
      profile_name "$profile"
      return 0
    fi
  done < <(find -L "$PROFILE_DIR" -maxdepth 1 -type f -name '*.lua' -print0)
}

profile_path_for_name() {
  local selected="$1"
  local profile

  while IFS= read -r -d '' profile; do
    if [[ "$(profile_name "$profile")" == "$selected" ]]; then
      printf '%s\n' "$profile"
      return 0
    fi
  done < <(find -L "$PROFILE_DIR" -maxdepth 1 -type f -name '*.lua' -print0)

  return 1
}

write_active_profile() {
  local source_profile="$1"

  mkdir -p "$USER_DIR"
  install -m 0644 "$source_profile" "$ACTIVE_PROFILE"
}

reload_hyprland() {
  if command_exists hyprctl; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
}

main() {
  require_command rofi "Install rofi first." || exit 1

  local profiles=()
  mapfile -t profiles < <(
    find -L "$PROFILE_DIR" -maxdepth 1 -type f -name '*.lua' \
      -exec basename {} .lua \; | sort -V
  )

  if ((${#profiles[@]} == 0)); then
    notify_error "Monitor Profile" "No profiles found in $PROFILE_DIR."
    exit 1
  fi

  rofi_close_existing

  local current selected source_profile
  current="$(current_profile_name)"
  selected="$(rofi_select_marked "$ROFI_THEME" "$MENU_MESSAGE" "$current" "›" "${profiles[@]}")" || exit 0
  [[ -n "$selected" ]] || exit 0

  if ! source_profile="$(profile_path_for_name "$selected")"; then
    notify_error "Monitor Profile" "Profile not found: $selected"
    exit 1
  fi

  write_active_profile "$source_profile"
  notify_success "Monitor Profile" "$selected loaded" "$(icon_img ja.png)" "monitor-profile"
  reload_hyprland
}

main "$@"
