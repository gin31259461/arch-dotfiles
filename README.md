# Arch Hyprland Dotfiles

Personal Arch Linux dotfiles for a Hyprland desktop, managed with
[Homebase](https://github.com/gin31259461/homebase) configuration in a bare Git
repository.

![Desktop preview](assets/preview.png)

This repository tracks the user-facing configuration needed to rebuild and
maintain the workstation: shell startup, desktop theming, Hyprland/Neovim
submodules, app settings, Homebase package groups, cleanup tasks, and setup
notes.

> [!NOTE]
> `$HOME` is the work tree and `~/.dotfiles/` is the Git directory. Use the
> `dot` alias from `.zshrc`, or pass `--git-dir` and `--work-tree` explicitly.

## What It Manages

- **Homebase platform config** in `.config/homebase/`, with `archlinux` selected
  automatically for Arch and Manjaro hosts.
- **Package groups** for Hyprland, shell tools, desktop apps, theming, fonts,
  input methods, AMD GPU support, Docker, Razer/MSI hardware, and development
  tooling.
- **Desktop configuration** for Kitty, Ghostty, GTK, Qt, Kvantum, Rofi,
  Quickshell, Noctalia, Cava, btop, Fastfetch, Swappy, Vesktop, Sunshine, and
  related app settings.
- **Shell setup** for Zsh, Oh My Zsh, Powerlevel10k, fzf, `lsd`, and a `dot`
  helper alias for the bare repository.
- **Submodules** for `.config/hypr` and `.config/nvim`.
- **Agent configuration** under `.agents/skills` and `.codex/agents`.

## Requirements

- Arch Linux or Manjaro
- `git`, `rsync`, `base-devel`, `go`, `ca-certificates`, `lsd`, `zsh`, and
  `openssh` for initial bootstrap
- `~/.local/bin/hb`, installed from the Homebase bootstrap flow

The Homebase platform file defines `pacman` as the official package manager and
`yay` for AUR packages.

## Get Started

On a fresh Arch-family machine, install Homebase and bootstrap this dotfiles
repo:

```bash
url=https://raw.githubusercontent.com/gin31259461/homebase/main/bootstrap
curl -fsSL "$url/archlinux.sh" | \
  bash -s -- --repo gin31259461/dotfiles-arch
```

Bootstrap and install every configured package group:

```bash
url=https://raw.githubusercontent.com/gin31259461/homebase/main/bootstrap
curl -fsSL "$url/archlinux.sh" | \
  bash -s -- --repo gin31259461/dotfiles-arch --yes --install
```

Once `hb` is installed, bootstrap directly:

```bash
hb bootstrap
```

Install configured packages:

```bash
hb install --all
```

Review and run cleanup tasks:

```bash
hb cleanup
```

Sync tracked dotfiles:

```bash
hb sync -m "Update dotfiles"
```

For unattended runs, pass `--yes` with an explicit `--group`, `--task`, or
`--all` selection.

> [!IMPORTANT]
> `hb sync` stages every path configured in
> `.config/homebase/platforms/archlinux/sync.toml`, including deletions. Review
> the bare-repo status before syncing.

## Daily Workflow

Check repository state:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --short
```

Use the shell alias after loading `.zshrc`:

```bash
dot status --short
```

Inspect Homebase commands:

```bash
hb --help
```

Install one package group:

```bash
hb install --group apps
```

Run one cleanup task:

```bash
hb cleanup --task journal
```

Sync without pushing:

```bash
hb sync -m "Update local config" --no-push
```

## Repository Layout

| Path | Purpose |
| --- | --- |
| `.config/homebase/` | Homebase platform selection, package groups, cleanup tasks, and sync path groups |
| `.config/hypr` | Hyprland submodule |
| `.config/nvim` | Neovim submodule |
| `.config/quickshell/`, `.local/state/noctalia/settings.toml` | Shell, overview, and Noctalia configuration |
| `.config/kitty/`, `.config/ghostty/`, `.config/rofi/` | Terminal and launcher configuration |
| `.agents/`, `.codex/agents/` | Local agent skills and Codex agent profiles |
| `doc/` | Arch install, maintenance, networking, VM, GPU, and disk notes |
| `assets/` | README preview assets |

## Notes

- Homebase runtime files live outside this repo at `~/.local/bin/hb` and
  `~/.local/lib/homebase/`.
- The current workflow is `hb bootstrap`, `hb install`, `hb cleanup`, and
  `hb sync`.
- Older notes may mention previous helper scripts; prefer the current `hb`
  commands when workflows conflict.
- Keep secrets, generated state, caches, and account-specific tokens out of the
  tracked sync groups unless intentionally adding them.
