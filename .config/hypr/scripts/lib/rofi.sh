#!/usr/bin/env bash
# Shared Rofi menu helpers.

_rofi_lib_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=common.sh
source "$_rofi_lib_dir/common.sh"
unset _rofi_lib_dir

rofi_close_existing() {
  kill_by_name rofi
}

rofi_dmenu() {
  local config="$1"
  local message="${2:-}"
  shift 2

  local args=(-i -dmenu)
  [[ -n "$config" ]] && args+=(-config "$config")
  [[ -n "$message" ]] && args+=(-mesg "$message")

  rofi "${args[@]}" "$@"
}

rofi_select_marked() {
  local config="$1"
  local message="$2"
  local current="$3"
  local marker="${4:-›}"
  shift 4

  local options=("$@")
  local default_row=0

  for i in "${!options[@]}"; do
    if [[ "${options[i]}" == "$current" ]]; then
      options[i]="$marker ${options[i]}"
      default_row="$i"
      break
    fi
  done

  local choice
  choice=$(printf '%s\n' "${options[@]}" \
    | rofi_dmenu "$config" "$message" -selected-row "$default_row") || return $?

  [[ -n "$choice" ]] && printf '%s\n' "${choice#"$marker "}"
}
