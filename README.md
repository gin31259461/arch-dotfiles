# Arch Linux Hyprland Dotfiles

Personal Arch Linux dotfiles for a Hyprland desktop, managed as a bare Git
repository in `~/.dotfiles` with `$HOME` as the work tree. Files live in their
normal locations, so there is no symlink farm to maintain.

Runtime setup is handled by **Homebase** (`hb`), a Go CLI that bootstraps the
machine, installs package groups, runs cleanup tasks, and syncs configured
dotfile paths.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Preview

![Hyprland desktop preview](./assets/preview.png)

## What Is Included

- Hyprland desktop config with Rofi, Quickshell, and Noctalia
- Zsh, Oh My Zsh, Powerlevel10k, terminal, Git, and editor defaults
- Kitty and Ghostty terminal configuration
- GTK, Qt, Kvantum, icon, cursor, font, and theme settings
- App config for btop, cava, fastfetch, swappy, Vesktop, Sunshine, and OneDrive
- Neovim and Hyprland config tracked as Git submodules
- Homebase bootstrap and management flow through `hb`
- TOML-backed package groups, cleanup tasks, and sync path groups
- Install, maintenance, hardware, virtual machine, and app notes in `doc/`

## Requirements

These dotfiles target Arch Linux. The remote bootstrap script installs only the
minimum needed to build and run Homebase:

- `git`
- `base-devel`
- `go`
- `rsync`
- `ca-certificates`

Homebase is cloned to `~/.local/lib/homebase`, built as `~/.local/bin/hb`, and
then takes over the remaining bootstrap and install tasks.

## Fresh Install

Run the bootstrap script from a fresh Arch Linux session:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh")
```

The bootstrap flow:

1. Installs the basic Arch packages needed to build Homebase
2. Clones or updates Homebase in `~/.local/lib/homebase`
3. Builds `~/.local/bin/hb`
4. Runs `hb bootstrap`
5. Clones the dotfiles as a bare repository into `~/.dotfiles`
6. Deploys tracked files into `$HOME`
7. Seeds `~/.config/homebase` when it is missing or empty
8. Hides untracked files from `dot status`
9. Adds the `dot` alias to `.zshrc` when needed
10. Initializes Git submodules
11. Offers to install Oh My Zsh, plugins, and Powerlevel10k

For a non-interactive bootstrap:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh") --yes
```

To run package installation immediately after bootstrap:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh") --yes --install
```

Use a fork or private remote with `--repo`:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/dotfiles-arch"
bash <(curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh") \
  --repo git@github.com:youruser/dotfiles-arch.git
```

The short GitHub form is accepted too:

```bash
hb bootstrap --repo youruser/dotfiles-arch
```

The selected remote is saved to `~/.dotfiles-repo`:

```toml
repo = "git@github.com:gin31259461/dotfiles-arch.git"
branch = "main"
```

## Homebase Commands

Homebase exposes one binary:

```bash
hb bootstrap
hb install
hb cleanup
hb sync
hb config init
```

Interactive commands use Bubble Tea and Lip Gloss. Automation should pass
explicit selections with `--yes`:

```bash
hb install --group core --group shell --yes
hb install --all --yes
hb cleanup --task pacman-cache --task journal --yes
hb cleanup --all --yes
```

## Configuration

Homebase copies default config from `~/.local/lib/homebase/config` to
`~/.config/homebase` when the config directory is missing or empty.

```text
~/.config/homebase/
|-- config.toml
|-- sync.toml
|-- cleanup.toml
`-- packages.d/
    |-- 10-system.toml
    |-- 20-desktop.toml
    |-- 30-appearance.toml
    |-- 40-apps.toml
    `-- 50-hardware-dev.toml
```

`config.toml` stores the Homebase clone location, dotfiles repo settings,
package manager choices, and bootstrap basics. `pacman` is used for official
packages and `yay` is the default AUR helper.

## Daily Use

Use `dot` for normal Git operations:

```bash
dot status
dot diff
dot add ~/.config/hypr/hyprland.conf
dot commit -m "feat(hypr): update monitor layout"
dot push origin main
```

Use `hb sync` to stage configured paths, commit, and push:

```bash
hb sync
hb sync -m "chore: sync dotfiles"
hb sync -m "chore: sync dotfiles" --no-push
```

The staged path groups are defined in `~/.config/homebase/sync.toml`.

## Install Packages

`hb install` installs selected package groups on Arch Linux. It skips packages
that are already installed and uses a Bubble Tea selector by default.

```bash
hb install
hb install --group core --group shell
hb install --group desktop --yes
hb install --all --yes
```

Package groups are defined in `~/.config/homebase/packages.d/*.toml`.

AUR packages are installed with the configured helper. The default is `yay`;
when `yay` is missing, Homebase builds it from the AUR.

Post-install setup that used to live in shell hooks is now implemented in Go:

- SDDM
- NetworkManager and dnsmasq
- Docker
- Razer/OpenRazer
- Sunshine
- tty1 autologin

## Clean System

`hb cleanup` runs configurable cleanup tasks:

```bash
hb cleanup
hb cleanup --task pacman-cache --task journal
hb cleanup --all --yes
```

Tasks are defined in `~/.config/homebase/cleanup.toml` and include:

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
|-- .dotfiles-repo
`-- .local/bin/
    `-- bootstrap.sh
```

Homebase source is intentionally separate from the dotfiles repo:

```text
~/.local/lib/homebase/
|-- cmd/hb/
|-- internal/
|-- config/
|-- go.mod
`-- go.sum
```

## Documentation

- [Arch install](doc/arch-install.md): dual-boot Arch Linux installation
- [Live USB](doc/live-usb.md): download, verify, and write an Arch ISO
- [AMD GPU](doc/amd-gpu.md): drivers, Vulkan, VA-API, and Hyprland variables
- [Disk migration](doc/disk-migration.md): move an install to a new drive
- [Disk expansion](doc/disk-expand.md): grow a partition online
