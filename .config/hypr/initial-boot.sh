#!/usr/bin/env bash
# Runs once on first boot to apply GTK/icon/cursor/kvantum theme defaults
# A bash script designed to run only once dotfiles installed

# NOT necessary to do since this script is only designed to run only once as long as the marker exists
# marker file is located at ~/.config/hypr/.initial_startup_done
# However, I do highly suggest not to touch it since again, as long as the marker exist, script wont run

# Variables
scriptsDir=$HOME/.config/hypr/scripts
kvantum_theme="catppuccin-mocha-blue"
color_scheme="prefer-dark"
gtk_theme="Flat-Remix-GTK-Blue-Dark"
icon_theme="Papirus"
cursor_theme="Bibata-Modern-Ice"

# Check if a marker file exists.
if [ ! -f "$HOME/.config/hypr/.initial_startup_done" ]; then
  sleep 1
  # initiate GTK dark mode and apply icon and cursor theme
  gsettings set org.gnome.desktop.interface color-scheme $color_scheme >/dev/null 2>&1 &
  gsettings set org.gnome.desktop.interface gtk-theme $gtk_theme >/dev/null 2>&1 &
  gsettings set org.gnome.desktop.interface icon-theme $icon_theme >/dev/null 2>&1 &
  gsettings set org.gnome.desktop.interface cursor-theme $cursor_theme >/dev/null 2>&1 &
  gsettings set org.gnome.desktop.interface cursor-size 24 >/dev/null 2>&1 &

  # initiate kvantum theme
  kvantummanager --set "$kvantum_theme" >/dev/null 2>&1 &

  # Create a marker file to indicate that the script has been executed.
  touch "$HOME/.config/hypr/.initial_startup_done"

  exit
fi
