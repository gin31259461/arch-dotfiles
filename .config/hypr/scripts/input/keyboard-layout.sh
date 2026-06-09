#!/usr/bin/env bash
# Manages keyboard layout switching across configured layouts

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

notif_icon="$(icon_img ja.png)"
scriptsDir="$SCRIPT_DIR"

ignore_patterns=(
  "--(avrcp)"
  "Bluetooth Speaker"
)

get_keyboard_names() {
  hyprctl devices -j | jq -r '.keyboards[].name'
}

is_ignored() {
  local device_name="$1"
  for pattern in "${ignore_patterns[@]}"; do
    if [[ "$device_name" == *"$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

get_current_layout_info() {
  local found_kb=false

  while read -r name; do
    if ! is_ignored "$name"; then
      found_kb=true
      local layout_mapping_str
      layout_mapping_str=$(hyprctl devices -j \
        | jq -r --arg name "$name" '.keyboards[] | select(.name==$name).layout')
      IFS="," read -r -a layout_mapping <<<"$layout_mapping_str"

      local variant_mapping_str
      variant_mapping_str=$(hyprctl devices -j \
        | jq -r --arg name "$name" '.keyboards[] | select(.name==$name).variant')
      IFS="," read -r -a variant_mapping <<<"$variant_mapping_str"

      layout_index=$(hyprctl devices -j \
        | jq -r --arg name "$name" '.keyboards[] | select(.name==$name).active_layout_index')
      break
    fi
  done <<<"$(get_keyboard_names)"

  $found_kb && return 0
  return 1
}

change_layout() {
  local error_found=false

  while read -r name; do
    if is_ignored "$name"; then
      echo "Skipping ignored device: $name"
      continue
    fi

    hyprctl switchxkblayout "$name" "$next_index"
    if [[ $? -ne 0 ]]; then
      echo "Error while switching layout for $name." >&2
      error_found=true
    fi
  done <<<"$(get_keyboard_names)"

  $error_found && return 1
  return 0
}

if ! get_current_layout_info; then
  echo "Could not get current layout information." >&2
  echo "There might not be any keyboards available, \
    or some were unnecessarily set as ignored." >&2
  notify_error "Keyboard Layout" "Layout change failed" "" "keyboard-layout" 2000
  echo "Exiting $0 $@" >&2
  exit 1
fi

current_layout=${layout_mapping[$layout_index]}
current_variant=${variant_mapping[$layout_index]}

if [[ "$1" == "status" ]]; then
  echo "$current_layout${current_variant:+($current_variant)}"
elif [[ "$1" == "switch" ]]; then
  echo "Current layout: $current_layout($current_variant)"

  layout_count=${#layout_mapping[@]}
  echo "Number of layouts: $layout_count"

  next_index=$(((layout_index + 1) % layout_count))
  new_layout="${layout_mapping[$next_index]}"
  new_variant="${variant_mapping[$next_index]}"
  echo "Next layout: $new_layout"

  if ! change_layout; then
    notify_error "Keyboard Layout" "Layout change failed" "" "keyboard-layout" 2000
    echo "Layout change failed." >&2
    exit 1
  else
    notify_success "Keyboard Layout" "$new_layout${new_variant:+($new_variant)}" "$notif_icon" "keyboard-layout"
    echo "Layout change notification sent."
  fi
else
  echo "Usage: $0 {status|switch}"
fi
