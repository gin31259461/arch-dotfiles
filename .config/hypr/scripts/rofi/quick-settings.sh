#!/usr/bin/env bash
# Quick Settings menu — config editor, rainbow borders, and utilities (SUPER SHIFT E)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

lua_conf="$HYPR_CONFIG_DIR/lua/hyprconf"
lua_user="$HYPR_CONFIG_DIR/lua/user"
term="${TERMINAL:-kitty}"
edit="${EDITOR:-nvim}"

scriptsDir="$SCRIPT_DIR"
rofi_theme="$ROFI_CONFIG_DIR/config-edit.rasi"
msg='Choose a setting'
iDIR="$SWAYNC_IMAGE_DIR"

show_info() {
  notify_info "Quick Settings" "$1" "$iDIR/info.png" "quick-settings"
}

rainbow_borders_menu() {
  local rainbow_script="$scriptsDir/display/rainbow-border.sh"
  local mode_file="$RAINBOW_BORDER_MODE_FILE"
  local refresh_script="$scriptsDir/services/refresh.sh"
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
  choice=$(printf "Disable Rainbow Borders\nWallust Color\nOriginal Rainbow\nGradient Flow" \
    | rofi_dmenu "$rofi_theme" "Rainbow Borders: current = $current_display")
  [[ -z "$choice" ]] && return

  case "$choice" in
    "Disable Rainbow Borders")
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
Configure Monitors (nwg-displays)
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
  choice=$(menu | rofi_dmenu "$rofi_theme" "$msg")

  case "$choice" in
    "Edit Environment & Defaults") file="$lua_conf/context.lua" ;;
    "Edit Keybinds") file="$lua_conf/binds.lua" ;;
    "Edit Autostart Apps") file="$lua_conf/autostart.lua" ;;
    "Edit Window Rules") file="$lua_conf/rules.lua" ;;
    "Edit Appearance") file="$lua_conf/options.lua" ;;
    "Edit Animations") file="$lua_user/animations.lua" ;;
    "Edit Input Settings") file="$lua_conf/options.lua" ;;
    "Edit Laptop Settings") file="$lua_conf/context.lua" ;;
    "Choose Kitty Terminal Theme") "$scriptsDir/display/kitty-themes.sh" ;;
    "Configure Monitors (nwg-displays)")
      require_command nwg-displays "Install nwg-displays first." || exit 1
      nwg-displays
      ;;
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
    "Choose Hyprland Animations") "$scriptsDir/profile-selector/animation" ;;
    "Choose Monitor Profiles") "$scriptsDir/profile-selector/monitor" ;;
    "Choose Rofi Themes") "$scriptsDir/rofi/rofi-theme-selector.sh" ;;
    "Search for Keybinds") "$scriptsDir/input/keybinds.sh" ;;
    "Toggle Game Mode") "$scriptsDir/session/game-mode.sh" ;;
    "Switch Dark-Light Theme") "$scriptsDir/display/dark-light.sh" ;;
    "Rainbow Borders Mode") rainbow_borders_menu ;;
    "Waybar Style") "$scriptsDir/display/waybar-style.sh" ;;
    "Waybar Layout") "$scriptsDir/display/waybar-layout.sh" ;;
    "Toggle Waybar")
      if noctalia_shell_manages waybar; then
        show_info "Waybar is managed by Noctalia shell."
        return
      fi
      if pgrep -x waybar >/dev/null; then
        kill_by_name waybar
      else
        waybar &
      fi
      ;;
    *) return ;;
  esac

  [[ -n "$file" ]] && "$term" -e "$edit" "$file"
}

rofi_close_existing

main
