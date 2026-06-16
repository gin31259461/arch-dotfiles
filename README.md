# Arch Linux and Hyprland Dotfiles

Personal dotfiles for Arch Linux and Hyprland.

The repository is managed as a bare git repo at `~/.dotfiles`, with `$HOME` as
the working tree. This keeps files in their normal locations without symlinks.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Preview

![Hyprland Dotfiles Preview](./assets/swappy-20260409-185633.png)

## What's Included

- **Shell:** `.zshrc`, `.zprofile`, `.p10k.zsh`, `.editorconfig`
- **GTK:** icon theme plus GTK 3 and GTK 4 config
- **Neovim:** `.config/nvim/`, tracked as an NvChad submodule
- **Terminal:** Kitty and Ghostty config
- **Compositor:** Hyprland config under `.config/hypr/`
- **Theming:** Kvantum, Qt, Wallust, icons, cursors, and related config
- **Shell UI:** Quickshell, Rofi, SwayNC, and Waybar
- **Utilities:** btop, cava, fastfetch, swappy, and Electron flags
- **Apps:** Discord, Vesktop, Noctalia, and selected app settings
- **Sync:** OneDrive config and sync list
- **Scripts:** bootstrap, dotfiles sync, package install, and cleanup scripts
- **Packages:** package groups and setup hooks under `.local/lib/dotfiles-arch/`
- **Self-hosted:** Sunshine config
- **Docs:** installation, maintenance, hardware, VM, and app notes

## Local Script Layout

Executable entrypoints live in `~/.local/bin/`. Shared implementation files,
TOML configuration, and setup hooks live under the `dotfiles-arch` namespace:

```text
~/.local/bin/
  bootstrap.sh
  cleanup.sh
  dotfiles.sh
  installer.sh

~/.local/lib/dotfiles-arch/
  config/
  core/
  optional/
  dotfiles-config.py
  tui.sh
```

## First-Time Setup

Create the bare repository:

```bash
mkdir "$HOME/.dotfiles"
git init --bare "$HOME/.dotfiles"
```

Add the `dot` alias to `.zshrc` or `.bashrc`:

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

Configure the remote and hide untracked file noise:

```bash
dot remote add origin <repo-url>
dot branch -m main
dot config --local status.showUntrackedFiles no
```

Run the sync script to stage, commit, and push tracked dotfiles:

```bash
dotfiles.sh
```

## Syncing Dotfiles

`~/.local/bin/dotfiles.sh` stages tracked paths, commits, and pushes.
Since `~/.local/bin` is in `PATH`, run it from anywhere:

```bash
dotfiles.sh
dotfiles.sh -m "update hypr config"
```

For manual operations, use the `dot` alias exactly like `git`:

```bash
dot status
dot diff
dot add ~/.config/hypr/hyprland.conf
dot commit -m "update hyprland config"
dot push origin main
```

## Installing Packages

`~/.local/bin/installer.sh` installs dotfile dependencies on a fresh
Arch Linux system. It groups packages by purpose, checks what is already
installed, and presents an interactive selection menu with `fzf` when
available.

```bash
installer.sh
installer.sh --yes
```

Package groups are defined in
`~/.local/lib/dotfiles-arch/config/packages.d/*.toml` and loaded by the
central parser at `~/.local/lib/dotfiles-arch/dotfiles-config.py`. Per-package
setup hooks live in `~/.local/lib/dotfiles-arch/core/` and
`~/.local/lib/dotfiles-arch/optional/`; the installer runs matching `setup()`
functions after installation.

AUR packages are installed via `yay`. If `yay` is not found, the script builds
and installs it automatically.

## System Cleanup

`~/.local/bin/cleanup.sh` frees disk space by cleaning caches and removing
orphaned packages. Each task shows the reclaimable size before confirmation.

```bash
cleanup.sh
cleanup.sh --yes
```

Cleanup task labels and descriptions are defined in
`~/.local/lib/dotfiles-arch/config/cleanup.toml` and parsed by
`~/.local/lib/dotfiles-arch/dotfiles-config.py`. The actual runners live in
`~/.local/bin/cleanup.sh`.

## Setting Up a New Machine

Run the bootstrap script on a fresh Arch Linux install:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh")
```

`bootstrap.sh` does the following:

1. Installs prerequisites with pacman.
1. Clones the bare dotfiles repo into `~/.dotfiles`.
1. Deploys tracked files to `$HOME`.
1. Configures git to hide untracked files in `$HOME`.
1. Adds the `dot` alias to `.zshrc` if missing.
1. Initializes all git submodules.
1. Offers to install Oh My Zsh, plugins, and Powerlevel10k.
1. Offers to run `installer.sh`.

Supported flags:

| Flag | Description |
| ---- | ----------- |
| `--yes`, `-y` | Skip optional prompts and accept defaults. |
| `--repo <url>`, `-r` | Use a custom dotfiles remote. |

### Custom Fork

Pass your SSH remote URL if you are not the default repo owner or want to
manage a personal fork:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh") \
  --repo git@github.com:youruser/dotfiles-arch.git
```

On first setup, the script clones the default repo over HTTPS, sets your SSH
URL as `origin`, patches the default repo values in `bootstrap.sh`, and writes
the selected remote to `~/.dotfiles-repo`.

After pushing those changes, later machines can use your fork directly:

```bash
repo_url="https://raw.githubusercontent.com/youruser/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh")
```

The short `user/repo` form is also accepted:

```bash
bootstrap.sh --repo youruser/dotfiles-arch
```

`~/.dotfiles-repo` is written by `bootstrap.sh` after each successful clone.
It contains the SSH URL configured for this machine's dotfiles remote and is
tracked so fresh machines can reuse it before cloning.

## Manual Bootstrap

Use these steps if you prefer not to run the bootstrap script:

```bash
git clone --separate-git-dir="$HOME/.dotfiles" \
  git@github.com:gin31259461/dotfiles-arch.git tmpdotfiles

rsync --recursive --verbose --exclude '.git' tmpdotfiles/ "$HOME/"
rm -rf tmpdotfiles

dot config --local status.showUntrackedFiles no
dot submodule update --init --recursive
```

## Documentation

- [Arch install](doc/arch-install.md): dual-boot installation guide
- [AMD GPU](doc/amd-gpu.md): drivers, Vulkan, VA-API, and Hyprland env vars
- [Live USB](doc/live-usb.md): download, verify, and write an Arch ISO
- [Disk migration](doc/disk-migration.md): move an install to a new drive
- [Disk expansion](doc/disk-expand.md): grow a partition online
- [Apps](doc/apps.md): Zsh, clipboard manager, and Fcitx5 notes
- [Maintenance](doc/maintenance.md): cleanup and upgrade notes
- [VMware](doc/vm.md): Hyprland guest notes and audio fixes

## References

- [JaKooLit/Hyprland-Dots][jakoolit-dots]

[jakoolit-dots]: https://github.com/JaKooLit/Hyprland-Dots
