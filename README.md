# Arch Linux and Hyprland Dotfiles

Personal dotfiles for Arch Linux with Hyprland.

This repo is managed as a bare Git repository at `~/.dotfiles`, with `$HOME`
as the work tree. Files stay in their normal locations, without symlinks.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Preview

![Hyprland desktop preview](./assets/swappy-20260409-185633.png)

## Contents

- Shell config for Zsh, Powerlevel10k, and editor defaults
- Hyprland, Waybar, Rofi, SwayNC, Quickshell, and related UI config
- Terminal config for Kitty and Ghostty
- Neovim config tracked as an NvChad submodule
- GTK, Qt, Kvantum, Wallust, icon, cursor, and theme settings
- App config for tools such as btop, cava, fastfetch, swappy, and Sunshine
- OneDrive sync config and selected app settings
- Scripts for bootstrap, package installation, cleanup, and dotfile sync
- Package definitions and setup hooks under `.local/lib/dotfiles-arch/`
- Documentation for install, maintenance, hardware, VM, and app notes

## Script Layout

Executable scripts live in `~/.local/bin/`:

```text
bootstrap.sh
cleanup.sh
dotfiles.sh
installer.sh
```

Shared code, TOML config, and setup hooks live under
`~/.local/lib/dotfiles-arch/`:

```text
config/
core/
optional/
dotfiles-config.py
tui.sh
```

## Fresh Install

Run the bootstrap script on a fresh Arch Linux install:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh")
```

The script installs prerequisites, clones the bare repo into `~/.dotfiles`,
checks out files into `$HOME`, hides untracked file noise, initializes
submodules, adds the `dot` alias when needed, and offers to run optional setup.

Supported flags:

| Flag | Description |
| ---- | ----------- |
| `--yes`, `-y` | Accept defaults and skip optional prompts. |
| `--repo <url>`, `-r` | Use a custom dotfiles remote. |

Use `--repo` for a fork or private remote:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh") \
  --repo git@github.com:youruser/dotfiles-arch.git
```

The short `user/repo` form is also accepted:

```bash
bootstrap.sh --repo youruser/dotfiles-arch
```

After a successful clone, the selected remote is written to `~/.dotfiles-repo`
so later installs can reuse it.

## Manual Setup

Use these steps if you do not want to run `bootstrap.sh`:

```bash
mkdir "$HOME/.dotfiles"
git init --bare "$HOME/.dotfiles"
dot remote add origin <repo-url>
dot branch -m main
dot config --local status.showUntrackedFiles no
```

To copy an existing remote into `$HOME`:

```bash
git clone --separate-git-dir="$HOME/.dotfiles" \
  git@github.com:gin31259461/dotfiles-arch.git tmpdotfiles

rsync --recursive --verbose --exclude '.git' tmpdotfiles/ "$HOME/"
rm -rf tmpdotfiles

dot config --local status.showUntrackedFiles no
dot submodule update --init --recursive
```

## Sync Dotfiles

`dotfiles.sh` stages tracked paths, commits, and pushes:

```bash
dotfiles.sh
dotfiles.sh -m "update hypr config"
```

For manual Git operations, use the `dot` alias:

```bash
dot status
dot diff
dot add ~/.config/hypr/hyprland.conf
dot commit -m "update hyprland config"
dot push origin main
```

## Install Packages

`installer.sh` installs dotfile dependencies on Arch Linux. It groups packages
by purpose, skips packages that are already installed, and uses an interactive
`fzf` menu when available.

```bash
installer.sh
installer.sh --yes
```

Package groups live in
`~/.local/lib/dotfiles-arch/config/packages.d/*.toml`. Setup hooks live in
`~/.local/lib/dotfiles-arch/core/` and
`~/.local/lib/dotfiles-arch/optional/`. The installer runs matching `setup()`
functions after package installation.

AUR packages use `yay`. If `yay` is missing, the installer builds and installs
it first.

## Clean System

`cleanup.sh` removes cache files and orphaned packages. Each task shows the
reclaimable size before confirmation.

```bash
cleanup.sh
cleanup.sh --yes
```

Cleanup task labels, descriptions, and requirements are defined in
`~/.local/lib/dotfiles-arch/config/cleanup.toml`.

## Documentation

- [Arch install](doc/arch-install.md): dual-boot installation guide
- [AMD GPU](doc/amd-gpu.md): drivers, Vulkan, VA-API, and Hyprland env vars
- [Live USB](doc/live-usb.md): download, verify, and write an Arch ISO
- [Disk migration](doc/disk-migration.md): move an install to a new drive
- [Disk expansion](doc/disk-expand.md): grow a partition online
- [Apps](doc/apps.md): Zsh, clipboard manager, and Fcitx5 notes
- [Maintenance](doc/maintenance.md): cleanup and upgrade notes
- [VMware](doc/vm.md): Hyprland guest notes and audio fixes

## Reference

- [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)
