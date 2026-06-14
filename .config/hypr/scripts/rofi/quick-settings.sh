#!/usr/bin/env bash
# Quick settings menu.

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

lua_conf="$HYPR_CONFIG_DIR/lua/hyprconf"
lua_user="$HYPR_CONFIG_DIR/lua/user"
term="${TERMINAL:-kitty}"
edit="${EDITOR:-nvim}"

rofi_theme="$ROFI_CONFIG_DIR/config-edit.rasi"
msg='Choose a setting'
marker="›"

show_info() {
  notify_info "Quick Settings" "$1" "$(icon_img info.png)" "quick-settings"
}

rainbow_borders_menu() {
  local rainbow_script="$SCRIPT_DIR/display/rainbow-border.sh"
  local mode_file="$RAINBOW_BORDER_MODE_FILE"
  local refresh_script="$SCRIPT_DIR/services/refresh.sh"
  local current

  current="$(rainbow_border_mode)"

  local current_display
  case "$current" in
    wallust_random) current_display="Wallust Color" ;;
    rainbow) current_display="Original Rainbow" ;;
    gradient_flow) current_display="Gradient Flow" ;;
    *) current_display="Disabled" ;;
  esac

  local choice
  choice=$(rofi_select_marked "$rofi_theme" "Rainbow Borders" "$current_display" "$marker" \
    "Disabled" \
    "Wallust Color" \
    "Original Rainbow" \
    "Gradient Flow") || return 0
  [[ -z "$choice" ]] && return

  case "$choice" in
    "Disabled")
      mkdir -p "$(dirname "$mode_file")"
      printf '%s\n' disabled >"$mode_file"
      current="disabled"
      command -v hyprctl &>/dev/null && hyprctl reload >/dev/null 2>&1 || true
      ;;
    "Wallust Color" | "Original Rainbow" | "Gradient Flow")
      local mode
      case "$choice" in
        "Wallust Color") mode="wallust_random" ;;
        "Original Rainbow") mode="rainbow" ;;
        "Gradient Flow") mode="gradient_flow" ;;
      esac
      if [[ ! -x "$rainbow_script" ]]; then
        show_info "Rainbow border script not found: $rainbow_script"
        return
      fi
      mkdir -p "$(dirname "$mode_file")"
      printf '%s\n' "$mode" >"$mode_file"
      current="$mode"
      ;;
    *) return ;;
  esac

  [[ -x "$refresh_script" ]] && "$refresh_script" >/dev/null 2>&1 &
  if [[ "$current" != "disabled" && -x "$rainbow_script" ]]; then
    "$rainbow_script" >/dev/null 2>&1 &
  fi
}

menu() {
  cat <<EOF
--- CONFIGURATION ---
Edit Environment & Defaults
Edit Keybinds
Edit Autostart Apps
Edit Window Rules
Edit Appearance
Edit Animations
Edit Input Settings
Edit Laptop Settings
--- UTILITIES ---
Choose Kitty Terminal Theme
GTK Settings (nwg-look)
QT Apps Settings (qt6ct)
QT Apps Settings (qt5ct)
Choose Hyprland Animations
Choose Monitor Profiles
Choose Rofi Themes
Search for Keybinds
Toggle Game Mode
Switch Dark-Light Theme
Rainbow Borders Mode
--- WAYBAR ---
Waybar Style
Waybar Layout
Toggle Waybar
EOF
}

main() {
  local choice file

  file=""
  choice=$(menu | rofi_dmenu "$rofi_theme" "$msg") || exit 0

  case "$choice" in
    "Edit Environment & Defaults") file="$lua_conf/context.lua" ;;
    "Edit Keybinds") file="$lua_conf/binds.lua" ;;
    "Edit Autostart Apps") file="$lua_conf/autostart.lua" ;;
    "Edit Window Rules") file="$lua_conf/rules.lua" ;;
    "Edit Appearance") file="$lua_conf/options.lua" ;;
    "Edit Animations") file="$lua_user/animations.lua" ;;
    "Edit Input Settings") file="$lua_conf/options.lua" ;;
    "Edit Laptop Settings") file="$lua_conf/context.lua" ;;
    "Choose Kitty Terminal Theme") "$SCRIPT_DIR/display/kitty-themes.sh" ;;
    # "Configure Monitors (nwg-displays)")
    #   require_command nwg-displays "Install nwg-displays first." || exit 1
    #   nwg-displays
    #   ;;
    "GTK Settings (nwg-look)")
      require_command nwg-look "Install nwg-look first." || exit 1
      nwg-look
      ;;
    "QT Apps Settings (qt6ct)")
      require_command qt6ct "Install qt6ct first." || exit 1
      qt6ct
      ;;
    "QT Apps Settings (qt5ct)")
      require_command qt5ct "Install qt5ct first." || exit 1
      qt5ct
      ;;
    "Choose Hyprland Animations") "$SCRIPT_DIR/profile-selector/animation" ;;
    "Choose Monitor Profiles") "$SCRIPT_DIR/profile-selector/monitor" ;;
    "Choose Rofi Themes") "$SCRIPT_DIR/rofi/rofi-theme-selector.sh" ;;
    "Search for Keybinds") "$SCRIPT_DIR/input/keybinds.sh" ;;
    "Toggle Game Mode") "$SCRIPT_DIR/session/game-mode.sh" ;;
    "Switch Dark-Light Theme") "$SCRIPT_DIR/display/dark-light.sh" ;;
    "Rainbow Borders Mode") rainbow_borders_menu ;;
    "Waybar Style") "$SCRIPT_DIR/display/waybar-style.sh" ;;
    "Waybar Layout") "$SCRIPT_DIR/display/waybar-layout.sh" ;;
    "Toggle Waybar")
      if noctalia_shell_manages waybar; then
        show_info "Waybar is managed by Noctalia shell."
        return
      fi
      if pgrep -x waybar >/dev/null; then
        kill_by_name waybar
      else
        start_waybar
      fi
      ;;
    *) return ;;
  esac

  [[ -n "$file" ]] && "$term" -e "$edit" "$file"
}

require_command rofi "Install rofi first." || exit 1
rofi_close_existing

main
