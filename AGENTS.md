# Arch Linux and Hyprland Dotfiles

Bare git repo, working tree is `$HOME`, bare repo at `~/.dotfiles/`.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Rules

- Use `dot` instead of `git` in `$HOME`
- `dot status` hides untracked files by design
- Commit always without co-author trailers

## Scripts (`~/.local/bin/`)

| Script | Purpose |
| ------ | ------- |
| `dotfiles.sh [-m "msg"]`              | Stage all tracked files, commit, push to `origin main`         |
| `bootstrap.sh [--yes] [--repo <url>]` | Fresh-machine setup: prereqs → clone → OMZ → packages          |
| `install-packages.sh [-y]`            | fzf group-select installer; calls `setup_<pkg>()` post-install |
| `cleanup.sh [-y]`                     | fzf task-select cleanup (pacman cache, orphans, journal, etc.) |

- To track a new file: add it to the `dot add` block in `dotfiles.sh`.

## Packages (`~/.local/lib/packages.sh`)

many groups: core, shell, terminal, bar, audio, network, capture, theming, fonts,
input, utils, wallpaper, dm, session, gtk, sync, self-hosted, apps, neovim,
noctalia, razer, amd, dev, docker, asus, msi, files, cleanup, etc.

Format: `"key|Label|official pkgs|AUR pkgs"`

## Package Setup Functions (`~/.local/lib/{core,optional}/*.sh`)

Auto-discovered by `install-packages.sh`.

Rules:

- Filename must match the package key (e.g. `sunshine.sh` → `setup()`).
- Setup packages via `*.sh -> setup()` after install for that package.
