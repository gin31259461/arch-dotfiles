# Arch Linux Hyprland Dotfiles

Personal Arch Linux dotfiles for a Hyprland desktop, managed as a bare Git
repository in `~/.dotfiles` with `$HOME` as the work tree. Files live in their
normal locations, so there is no symlink farm to maintain.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Preview

![Hyprland desktop preview](./assets/swappy-20260409-185633.png)

## What Is Included

- Hyprland desktop config with Waybar, Rofi, SwayNC, Quickshell, and Noctalia
- Zsh, Oh My Zsh, Powerlevel10k, terminal, Git, and editor defaults
- Kitty and Ghostty terminal configuration
- GTK, Qt, Kvantum, Wallust, icon, cursor, font, and theme settings
- App config for btop, cava, fastfetch, swappy, Vesktop, Sunshine, and OneDrive
- Neovim and Hyprland config tracked as Git submodules
- Bootstrap, package installation, cleanup, and dotfile sync scripts
- TOML-backed package groups, cleanup tasks, and tracked path groups
- Install, maintenance, hardware, virtual machine, and app notes in `doc/`

## Requirements

These dotfiles target Arch Linux. The bootstrap script installs the base tools
it needs when missing:

- `git`
- `rsync`
- `base-devel`
- `python`
- `fzf`
- `gum`

Runtime dependencies are handled by `installer.sh` and defined in
`.local/lib/dotfiles-arch/config/packages.d/*.toml`.

## Fresh Install

Run the bootstrap script from a fresh Arch Linux session:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh")
```

The bootstrap flow:

1. Installs prerequisite packages
2. Clones the dotfiles as a bare repository into `~/.dotfiles`
3. Deploys tracked files into `$HOME`
4. Hides untracked files from `dot status`
5. Adds the `dot` alias to `.zshrc` when needed
6. Initializes Git submodules
7. Offers to install Oh My Zsh, Zsh plugins, and Powerlevel10k
8. Offers to run the package installer

For a non-interactive run:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh") --yes
```

Use a fork or private remote with `--repo`:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh") \
  --repo git@github.com:youruser/dotfiles-arch.git
```

The short GitHub form is accepted too:

```bash
bootstrap.sh --repo youruser/dotfiles-arch
```

The selected SSH remote is saved to `~/.dotfiles-repo` for later bootstraps.

## Manual Setup

Use these steps when you want to set up the bare repository yourself.

```bash
git clone --separate-git-dir="$HOME/.dotfiles" \
  git@github.com:gin31259461/dotfiles-arch.git tmpdotfiles

rsync --recursive --verbose --exclude '.git' tmpdotfiles/ "$HOME/"
rm -rf tmpdotfiles

alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dot config --local status.showUntrackedFiles no
dot submodule update --init --recursive
```

For a new empty bare repository:

```bash
mkdir "$HOME/.dotfiles"
git init --bare "$HOME/.dotfiles"
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

dot remote add origin <repo-url>
dot branch -m main
dot config --local status.showUntrackedFiles no
```

## Daily Use

Use `dot` for normal Git operations:

```bash
dot status
dot diff
dot add ~/.config/hypr/hyprland.conf
dot commit -m "feat(hypr): update monitor layout"
dot push origin main
```

Use `dotfiles.sh` to stage configured paths, commit, and push in one command:

```bash
dotfiles.sh
dotfiles.sh -m "chore: sync dotfiles"
```

The staged path groups are defined in
`.local/lib/dotfiles-arch/config/dotfiles.toml`.

## Install Packages

`installer.sh` installs selected package groups on Arch Linux. It skips packages
that are already installed, uses `fzf` when available, and falls back to a
numbered menu otherwise.

```bash
installer.sh
installer.sh --yes
```

Package groups are defined in:

```text
.local/lib/dotfiles-arch/config/packages.d/
```

Current groups cover:

- Core Hyprland, shell, CLI tools, terminals, and SDDM
- File management, audio, networking, Bluetooth, screenshots, and clipboard
- Themes, fonts, Qt/GTK tooling, and Fcitx5
- Desktop apps, cloud sync, self-hosted tools, Noctalia, and Neovim
- AMD GPU, Docker, development tools, Razer, ASUS ROG, and MSI utilities

AUR packages are installed with `yay`. If `yay` is missing, the installer
builds and installs it first.

Setup hooks live in:

```text
.local/lib/dotfiles-arch/core/
.local/lib/dotfiles-arch/optional/
```

## Clean System

`cleanup.sh` runs configurable cleanup tasks and shows reclaimable size where
possible before asking for confirmation.

```bash
cleanup.sh
cleanup.sh --yes
```

Tasks are defined in `.local/lib/dotfiles-arch/config/cleanup.toml` and include:

- Pacman package cache with `paccache -r`
- AUR build cache under `~/.cache/yay`
- Orphaned packages with `pacman -Rns`
- Systemd journal entries older than two weeks
- npm cache when `npm` is installed
- Thumbnail cache under `~/.cache/thumbnails`

## Repository Layout

```text
.
|-- README.md
|-- AGENTS.md
|-- assets/
|-- doc/
|-- .config/
|-- .local/bin/
|   |-- bootstrap.sh
|   |-- cleanup.sh
|   |-- dotfiles.sh
|   `-- installer.sh
`-- .local/lib/dotfiles-arch/
    |-- config/
    |   |-- cleanup.toml
    |   |-- dotfiles.toml
    |   `-- packages.d/
    |-- core/
    |-- optional/
    |-- dotfiles-config.py
    `-- tui.sh
```

## Documentation

- [Arch install](doc/arch-install.md): dual-boot Arch Linux installation
- [Live USB](doc/live-usb.md): download, verify, and write an Arch ISO
- [AMD GPU](doc/amd-gpu.md): drivers, Vulkan, VA-API, and Hyprland variables
- [Disk migration](doc/disk-migration.md): move an install to a new drive
- [Disk expansion](doc/disk-expand.md): grow a partition online
- [Apps](doc/apps.md): Zsh, clipboard manager, and Fcitx5 notes
- [Maintenance](doc/maintenance.md): cleanup and upgrade notes
- [VMware](doc/vm.md): Hyprland guest notes and audio fixes

## References

- [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)
