cd $HOME

alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# self and github files
dot add README.md dotfiles.sh .gitconfig
# .gitmodules

# zsh
dot add .zshrc .zprofile .p10k.zsh

# flags
dot add .config/electron-flags.conf
# .config/code-flags.conf

# terminal
dot add .config/kitty

# hyprland
dot add .config/hypr/UserConfigs .config/hypr/UserScripts

# gtk
dot add .icons .config/gtk-3.0

dot commit -m "Sync dotfiles"
dot push origin main
