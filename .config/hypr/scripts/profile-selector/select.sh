#!/usr/bin/env bash
# Selects a profile category and writes the chosen profile into lua/user.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

PROFILE_ROOT="$HYPR_CONFIG_DIR/profiles"
STATE_DIR="$PROFILE_ROOT/.selected"
USER_DIR="$HYPR_CONFIG_DIR/lua/user"
MARKER="›"

category_title() {
  local category="$1"

  printf '%s\n' "${category^}"
}

profile_key() {
  basename "$1" .lua
}

profile_label() {
  local file="$1"
  local label

  label="$(sed -n '1,8{s/^-- profile:[[:space:]]*//p}' "$file" | head -n 1)"
  if [[ -n "$label" ]]; then
    printf '%s\n' "$label"
  else
    profile_key "$file"
  fi
}

target_for_category() {
  local category="$1"

  case "$category" in
    animation) printf '%s/animations.lua\n' "$USER_DIR" ;;
    monitor) printf '%s/monitors.lua\n' "$USER_DIR" ;;
    *) printf '%s/%s.lua\n' "$USER_DIR" "$category" ;;
  esac
}

profile_dir_for_category() {
  printf '%s/%s\n' "$PROFILE_ROOT" "$1"
}

state_file_for_category() {
  printf '%s/%s\n' "$STATE_DIR" "$1"
}

theme_for_category() {
  local category="$1"

  case "$category" in
    animation) printf '%s/config-animations.rasi\n' "$ROFI_CONFIG_DIR" ;;
    monitor) printf '%s/config-monitors.rasi\n' "$ROFI_CONFIG_DIR" ;;
    *) printf '%s/config-edit.rasi\n' "$ROFI_CONFIG_DIR" ;;
  esac
}

remember_selected_profile() {
  local category="$1"
  local source_profile="$2"

  mkdir -p "$STATE_DIR"
  printf '%s\n' "$(profile_key "$source_profile")" >"$(state_file_for_category "$category")"
}

current_profile_key() {
  local category="$1"
  local profile_dir="$2"
  local active_profile="$3"
  local state_file

  state_file="$(state_file_for_category "$category")"
  if [[ -f "$state_file" ]]; then
    local selected
    selected="$(<"$state_file")"
    if [[ -f "$profile_dir/$selected.lua" ]]; then
      printf '%s\n' "$selected"
      return 0
    fi
  fi

  [[ -f "$active_profile" ]] || return 0

  local profile
  while IFS= read -r -d '' profile; do
    if cmp -s "$profile" "$active_profile"; then
      profile_key "$profile"
      return 0
    fi
  done < <(find -L "$profile_dir" -maxdepth 1 -type f -name '*.lua' -print0)
}

write_active_profile() {
  local source_profile="$1"
  local active_profile="$2"

  mkdir -p "$(dirname "$active_profile")"
  install -m 0644 "$source_profile" "$active_profile"
}

reload_hyprland() {
  if command_exists hyprctl; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
}

select_category() {
  local categories=()
  mapfile -t categories < <(
    find -L "$PROFILE_ROOT" -mindepth 1 -maxdepth 1 -type d \
      ! -name '.*' -exec basename {} \; | sort -V
  )

  if ((${#categories[@]} == 0)); then
    notify_error "Profile Selector" "No profile categories found in $PROFILE_ROOT."
    exit 1
  fi

  rofi_select_marked "$ROFI_CONFIG_DIR/config-edit.rasi" "Choose profile category" "" "$MARKER" "${categories[@]}"
}

select_profile() {
  local category="$1"
  local profile_dir active_profile current_key current_label

  profile_dir="$(profile_dir_for_category "$category")"
  active_profile="$(target_for_category "$category")"

  if [[ ! -d "$profile_dir" ]]; then
    notify_error "Profile Selector" "No profiles found for category: $category"
    exit 1
  fi

  local profiles=()
  mapfile -d '' -t profiles < <(
    find -L "$profile_dir" -maxdepth 1 -type f -name '*.lua' -print0 | sort -zV
  )

  if ((${#profiles[@]} == 0)); then
    notify_error "Profile Selector" "No Lua profiles found in $profile_dir."
    exit 1
  fi

  current_key="$(current_profile_key "$category" "$profile_dir" "$active_profile")"
  current_label=""

  local labels=()
  local profile label
  for profile in "${profiles[@]}"; do
    label="$(profile_label "$profile")"
    labels+=("$label")
    if [[ "$(profile_key "$profile")" == "$current_key" ]]; then
      current_label="$label"
    fi
  done

  local selected
  selected="$(rofi_select_marked "$(theme_for_category "$category")" "Choose $(category_title "$category") profile" "$current_label" "$MARKER" "${labels[@]}")" || exit 0
  [[ -n "$selected" ]] || exit 0

  for i in "${!labels[@]}"; do
    if [[ "${labels[i]}" == "$selected" ]]; then
      write_active_profile "${profiles[i]}" "$active_profile"
      remember_selected_profile "$category" "${profiles[i]}"
      notify_success "$(category_title "$category") Profile" "$selected loaded" "$(icon_img ja.png)" "$category-profile"
      reload_hyprland
      return 0
    fi
  done

  notify_error "Profile Selector" "Profile not found: $selected"
  exit 1
}

main() {
  require_command rofi "Install rofi first." || exit 1
  rofi_close_existing

  local category="${1:-}"
  if [[ -z "$category" ]]; then
    category="$(select_category)" || exit 0
  fi
  [[ -n "$category" ]] || exit 0

  select_profile "$category"
}

main "$@"
