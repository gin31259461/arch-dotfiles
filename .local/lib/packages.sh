#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  packages.sh  ·  Package group definitions for install-packages.sh
#
#  Format per entry:
#    "key|Display Label|official packages (space-sep)|AUR packages (space-sep)"
#
#  To add a new package:   append to the official or AUR field of the group.
#  To add a new group:     append a new entry to PKG_GROUPS.
# ─────────────────────────────────────────────────────────────────────────────

declare -a PKG_GROUPS=(
  "core|Core Hyprland\
|hyprland hyprpolkitagent hyprlock hypridle hyprsunset \
xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
uwsm libnewt\
|"
  "shell|Shell & Prompt\
|zsh zsh-completions fzf gum lsd fastfetch\
|"
  "terminal|Terminals\
|kitty ghostty\
|"
  "files|File Manager\
|thunar thunar-archive-plugin thunar-volman tumbler gvfs gvfs-mtp ffmpegthumbnailer xarchiver\
|"
  "bar|Bar & Notifications\
|waybar\
|"
  "audio|Audio\
|pipewire pipewire-alsa pipewire-audio pipewire-pulse wireplumber \
pamixer pavucontrol playerctl mpv mpv-mpris\
|"
  "network|Network & Bluetooth\
|networkmanager network-manager-applet bluez bluez-utils blueman \
networkmanager-openconnect networkmanager-openvpn\
|"
  "capture|Screenshot & Clipboard\
|grim slurp swappy cliphist wl-clipboard libnotify\
|"
  "theming|Qt Theming\
|kvantum qt5ct qt6ct qt6-5compat nwg-look nwg-displays \
papirus-icon-theme gtk-engine-murrine\
|"
  "fonts|Fonts\
|noto-fonts noto-fonts-emoji otf-font-awesome \
ttf-jetbrains-mono-nerd ttf-firacode-nerd ttf-fantasque-nerd \
adobe-source-code-pro-fonts ttf-droid ttf-fira-code ttf-jetbrains-mono\
|ttf-victor-mono noto-fonts-tc-vf"
  "input|Input Method (fcitx5)\
|fcitx5 fcitx5-chewing fcitx5-gtk fcitx5-qt fcitx5-configtool\
|"
  "utils|Utilities\
|btop cava brightnessctl bc jq imagemagick chafa \
xdg-user-dirs yad rofi xdotool rsync wget unzip pacman-contrib \
qalculate-gtk nvtop yt-dlp baobab inxi power-profiles-daemon\
|octopi"
  "wallpaper|Wallpaper & Colors\
|\
|swww wallust"
  "dm|Display Manager\
|sddm\
|"
  "session|Session & Logout\
|\
|wlogout"
  "gtk|GTK Theme & Cursor\
|\
|adw-gtk-theme"
  "sync|Cloud Sync\
|\
|onedrive-abraunegg"
  "self-hosted|Self-hosted & VPN\
|tailscale\
|sunshine"
  "apps|Applications\
|obsidian remmina vlc loupe\
|vesktop-bin zen-browser-bin onlyoffice-bin"
  "neovim|Neovim Editor\
|lazygit neovim\
|"
  "noctalia|Noctalia Shell\
|\
|noctalia-shell noctalia-qs quickshell-overview-git"
  "razer|Razer Devices\
|openrazer-daemon openrazer-driver-dkms\
|polychromatic"
  "amd|AMD GPU Drivers\
|vulkan-radeon lib32-vulkan-radeon libva-utils amd-ucode amdgpu_top vulkan-tools\
|"
  "dev|Dev Tools\
|git npm pass\
|git-credential-manager-bin"
  "docker|Docker\
|docker docker-compose docker-buildx\
|lazydocker-bin"
  "asus|ASUS ROG\
|\
|asusctl rog-control-center supergfxctl"
  "msi|MSI\
|\
|msi-ec mcontrolcenter-bin"
)
