#!/usr/bin/env bash
# Toggles between dark and light theme for system and applications
# Note: Scripts look for keywords Light or Dark; wallpapers are in separate directories

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"

hypr_config_path="$HYPR_CONFIG_DIR"
swaync_style="$HOME/.config/swaync/style.css"
ags_style="$HOME/.config/ags/user/style.css"
scriptsDir="$SCRIPT_DIR"
notif="$(icon_img bell.png)"
wallust_rofi="$HOME/.config/wallust/templates/colors-rofi.rasi"

kitty_conf="$HOME/.config/kitty/kitty.conf"

wallust_config="$HOME/.config/wallust/wallust.toml"
pallete_dark="dark16"
pallete_light="light16"
qt5ct_dark="$HOME/.config/qt5ct/colors/Catppuccin-Mocha.conf"
qt5ct_light="$HOME/.config/qt5ct/colors/Catppuccin-Latte.conf"
qt6ct_dark="$HOME/.config/qt6ct/colors/Catppuccin-Mocha.conf"
qt6ct_light="$HOME/.config/qt6ct/colors/Catppuccin-Latte.conf"

if [[ "$(cat "$HOME/.cache/.theme_mode")" == "Light" ]]; then
  next_mode="Dark"
else
  next_mode="Light"
fi

if [[ "$next_mode" == "Dark" ]]; then
  qt5ct_color_scheme="$qt5ct_dark"
  qt6ct_color_scheme="$qt6ct_dark"
else
  qt5ct_color_scheme="$qt5ct_light"
  qt6ct_color_scheme="$qt6ct_light"
fi

update_theme_mode() {
  echo "$next_mode" >"$HOME/.cache/.theme_mode"
}

notify_user() {
  notify_info "Theme" "Switching to $1 mode" "$notif" "theme-mode"
}

if [[ "$next_mode" == "Dark" ]]; then
  sed -i 's/^palette = .*/palette = "'"$pallete_dark"'"/' "$wallust_config"
else
  sed -i 's/^palette = .*/palette = "'"$pallete_light"'"/' "$wallust_config"
fi

notify_user "$next_mode"

# swaync color change
if [[ "$next_mode" == "Dark" ]]; then
  sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.8);/' "${swaync_style}"
else
  sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.9);/' "${swaync_style}"
fi

# ags color change
if command -v ags >/dev/null 2>&1; then
  if [[ "$next_mode" == "Dark" ]]; then
    sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.4);/' "${ags_style}"
    sed -i '/@define-color text-color/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.7);/' "${ags_style}"
    sed -i '/@define-color noti-bg-alt/s/#.*;/#111111;/' "${ags_style}"
  else
    sed -i '/@define-color noti-bg/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(255, 255, 255, 0.4);/' "${ags_style}"
    sed -i '/@define-color text-color/s/rgba([0-9]*,\s*[0-9]*,\s*[0-9]*,\s*[0-9.]*);/rgba(0, 0, 0, 0.7);/' "${ags_style}"
    sed -i '/@define-color noti-bg-alt/s/#.*;/#F0F0F0;/' "${ags_style}"
  fi
fi

# kitty background color change
if [[ "$next_mode" == "Dark" ]]; then
  sed -i '/^foreground /s/^foreground .*/foreground #dddddd/' "${kitty_conf}"
  sed -i '/^background /s/^background .*/background #000000/' "${kitty_conf}"
  sed -i '/^cursor /s/^cursor .*/cursor #dddddd/' "${kitty_conf}"
else
  sed -i '/^foreground /s/^foreground .*/foreground #000000/' "${kitty_conf}"
  sed -i '/^background /s/^background .*/background #dddddd/' "${kitty_conf}"
  sed -i '/^cursor /s/^cursor .*/cursor #000000/' "${kitty_conf}"
fi

while IFS= read -r pid; do
  kill -SIGUSR1 "$pid"
done < <(pidof kitty | tr ' ' '\n')

# Set Kvantum Manager theme & QT5/QT6 settings
if [[ "$next_mode" == "Dark" ]]; then
  kvantum_theme="catppuccin-mocha-blue"
else
  kvantum_theme="catppuccin-latte-blue"
fi

sed -i "s|^color_scheme_path=.*$|color_scheme_path=$qt5ct_color_scheme|" "$HOME/.config/qt5ct/qt5ct.conf"
sed -i "s|^color_scheme_path=.*$|color_scheme_path=$qt6ct_color_scheme|" "$HOME/.config/qt6ct/qt6ct.conf"
kvantummanager --set "$kvantum_theme"

# Set rofi background color
if [[ "$next_mode" == "Dark" ]]; then
  sed -i '/^background:/s/.*/background: rgba(0,0,0,0.7);/' "$wallust_rofi"
else
  sed -i '/^background:/s/.*/background: rgba(255,255,255,0.9);/' "$wallust_rofi"
fi

set_custom_gtk_theme() {
  local mode="$1"
  local gtk_themes_directory="$HOME/.themes"
  local icon_directory="$HOME/.icons"
  local search_keywords

  if [[ "$mode" == "Light" ]]; then
    search_keywords="*Light*"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
  elif [[ "$mode" == "Dark" ]]; then
    search_keywords="*Dark*"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  else
    echo "Invalid mode provided."
    return 1
  fi

  local themes=()
  local icons=()

  while IFS= read -r -d '' theme_search; do
    themes+=("$(basename "$theme_search")")
  done < <(find "$gtk_themes_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

  while IFS= read -r -d '' icon_search; do
    icons+=("$(basename "$icon_search")")
  done < <(find "$icon_directory" -maxdepth 1 -type d -iname "$search_keywords" -print0)

  if [[ ${#themes[@]} -gt 0 ]]; then
    local selected_theme="${themes[$RANDOM % ${#themes[@]}]}"
    echo "Selected GTK theme for $mode mode: $selected_theme"
    gsettings set org.gnome.desktop.interface gtk-theme "$selected_theme"

    if command -v flatpak &>/dev/null; then
      flatpak --user override --filesystem="$HOME/.themes"
      sleep 0.5
      flatpak --user override --env=GTK_THEME="$selected_theme"
    fi
  else
    echo "No $mode GTK theme found"
  fi

  if [[ ${#icons[@]} -gt 0 ]]; then
    local selected_icon="${icons[$RANDOM % ${#icons[@]}]}"
    echo "Selected icon theme for $mode mode: $selected_icon"
    gsettings set org.gnome.desktop.interface icon-theme "$selected_icon"

    sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$HOME/.config/qt5ct/qt5ct.conf"
    sed -i "s|^icon_theme=.*$|icon_theme=$selected_icon|" "$HOME/.config/qt6ct/qt6ct.conf"

    if command -v flatpak &>/dev/null; then
      flatpak --user override --filesystem="$HOME/.icons"
      sleep 0.5
      flatpak --user override --env=ICON_THEME="$selected_icon"
    fi
  else
    echo "No $mode icon theme found"
  fi
}

set_custom_gtk_theme "$next_mode"

update_theme_mode

sleep 2
kill_by_name rofi swaync ags swaybg

sleep 1
"${scriptsDir}/services/refresh.sh"

sleep 0.5
notify_success "Theme" "$next_mode mode applied" "$notif" "theme-mode"

exit 0
