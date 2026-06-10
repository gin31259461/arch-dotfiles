#!/usr/bin/env bash
# Preview and apply rofi themes.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

rofi_themes_dir_config="$ROFI_CONFIG_DIR/themes"
rofi_themes_dir_local="${XDG_DATA_HOME:-$HOME/.local/share}/rofi/themes"
rofi_config_file="$ROFI_CONFIG_DIR/config.rasi"
rofi_picker_theme="$ROFI_CONFIG_DIR/config-theme-selector.rasi"
max_theme_history=10
committed=0
original_rofi_config_file=""

restore_original_config() {
  if ((committed)); then
    rm -f "$original_rofi_config_file"
    return
  fi

  if [[ -n "$original_rofi_config_file" && -f "$original_rofi_config_file" ]]; then
    install -m 0644 "$original_rofi_config_file" "$rofi_config_file"
    rm -f "$original_rofi_config_file"
  fi
}

theme_config_path() {
  local path="$1"

  if [[ "$path" == "$HOME/"* ]]; then
    printf '~/%s\n' "${path#"$HOME/"}"
  else
    printf '%s\n' "$path"
  fi
}

canonical_theme_name() {
  local name="$1"

  name="$(basename "$name")"
  name="${name%.rasi}"
  name="${name#KooL_}"
  name="${name,,}"
  name="${name//_/-}"

  case "$name" in
    lonerorz) name="loner-orz" ;;
  esac

  printf '%s.rasi\n' "$name"
}

theme_path_for_name() {
  local theme_name="$1"

  if [[ -f "$rofi_themes_dir_config/$theme_name" ]]; then
    printf '%s\n' "$rofi_themes_dir_config/$theme_name"
  elif [[ -f "$rofi_themes_dir_local/$theme_name" ]]; then
    printf '%s\n' "$rofi_themes_dir_local/$theme_name"
  else
    return 1
  fi
}

prune_theme_history() {
  local lines=()

  mapfile -t lines < <(grep -n '^[[:space:]]*//[[:space:]]*@theme' "$rofi_config_file" | cut -d: -f1)
  ((${#lines[@]} <= max_theme_history)) && return

  local remove_count=$((${#lines[@]} - max_theme_history))
  local i
  for ((i = remove_count - 1; i >= 0; i--)); do
    sed -i "${lines[i]}d" "$rofi_config_file"
  done
}

apply_rofi_theme() {
  local theme_name="$1"
  local theme_path theme_ref temp_file

  theme_path="$(theme_path_for_name "$theme_name")" || {
    notify_error "Rofi Theme" "Theme file not found: $theme_name" "$(icon_img error.png)" "rofi-theme"
    return 1
  }
  theme_ref="$(theme_config_path "$theme_path")"
  temp_file="$(mktemp)"

  awk -v theme_ref="$theme_ref" '
    /^[[:space:]]*@theme[[:space:]]/ {
      print "//" $0
      next
    }
    { print }
    END {
      print ""
      print "@theme \"" theme_ref "\""
    }
  ' "$rofi_config_file" >"$temp_file"

  install -m 0644 "$temp_file" "$rofi_config_file"
  rm -f "$temp_file"
  prune_theme_history
}

load_available_themes() {
  local file theme_name
  local -A seen=()

  available_theme_names=()
  while IFS= read -r -d '' file; do
    theme_name="$(basename "$file")"
    [[ "$theme_name" == KooL_* ]] && continue
    [[ -n "${seen[$theme_name]+x}" ]] && continue

    seen[$theme_name]=1
    available_theme_names+=("$theme_name")
  done < <(
    {
      [[ -d "$rofi_themes_dir_config" ]] && find "$rofi_themes_dir_config" -maxdepth 1 -type f -name '*.rasi' -print0
      [[ -d "$rofi_themes_dir_local" ]] && find "$rofi_themes_dir_local" -maxdepth 1 -type f -name '*.rasi' -print0
    } | sort -zV
  )
}

current_theme_index() {
  local current_theme current_name i

  current_theme="$(grep -oE '^[[:space:]]*@theme[[:space:]]+"[^"]+"' "$rofi_config_file" | sed -E 's/^[[:space:]]*@theme[[:space:]]+"([^"]+)".*/\1/' | tail -n 1 || true)"
  current_name="$(canonical_theme_name "$current_theme")"

  for i in "${!available_theme_names[@]}"; do
    if [[ "${available_theme_names[i]}" == "$current_name" ]]; then
      printf '%s\n' "$i"
      return
    fi
  done

  printf '0\n'
}

theme_labels() {
  local theme_name

  for theme_name in "${available_theme_names[@]}"; do
    printf '%s\n' "${theme_name%.rasi}"
  done
}

select_theme() {
  local current_index="$1"
  local chosen_index rofi_status

  rofi_status=0
  chosen_index="$(
    theme_labels | rofi_dmenu "$rofi_picker_theme" "Enter: Preview | Ctrl+S: Apply | Esc: Cancel" \
      -format i \
      -p "Rofi Theme" \
      -selected-row "$current_index" \
      -kb-custom-1 "Control+s"
  )" || rofi_status=$?

  printf '%s:%s\n' "$rofi_status" "$chosen_index"
}

valid_index() {
  local index="$1"

  [[ "$index" =~ ^[0-9]+$ ]] && ((index >= 0 && index < ${#available_theme_names[@]}))
}

main() {
  require_command rofi "Install rofi first." || exit 1

  if [[ ! -f "$rofi_config_file" ]]; then
    notify_error "Rofi Theme" "Rofi config not found: $rofi_config_file" "$(icon_img error.png)" "rofi-theme"
    exit 1
  fi

  load_available_themes
  if ((${#available_theme_names[@]} == 0)); then
    notify_error "Rofi Theme" "No .rasi themes found." "$(icon_img error.png)" "rofi-theme"
    exit 1
  fi

  original_rofi_config_file="$(mktemp)"
  cp "$rofi_config_file" "$original_rofi_config_file"
  trap restore_original_config EXIT

  rofi_close_existing

  local current_index selection rofi_status chosen_index preview_name
  current_index="$(current_theme_index)"

  while true; do
    preview_name="${available_theme_names[current_index]}"
    apply_rofi_theme "$preview_name"

    selection="$(select_theme "$current_index")"
    rofi_status="${selection%%:*}"
    chosen_index="${selection#*:}"

    case "$rofi_status" in
      0)
        valid_index "$chosen_index" && current_index="$chosen_index"
        ;;
      1 | 65)
        notify_info "Rofi Theme" "Selection cancelled. Reverted original theme." "$(icon_img note.png)" "rofi-theme"
        exit 0
        ;;
      10)
        valid_index "$chosen_index" && current_index="$chosen_index"
        preview_name="${available_theme_names[current_index]}"
        apply_rofi_theme "$preview_name"
        committed=1
        notify_success "Rofi Theme Applied" "${preview_name%.rasi}" "$(icon_img ja.png)" "rofi-theme"
        exit 0
        ;;
      *)
        notify_error "Rofi Theme" "Unexpected rofi exit: $rofi_status" "$(icon_img error.png)" "rofi-theme"
        exit 1
        ;;
    esac
  done
}

main "$@"
