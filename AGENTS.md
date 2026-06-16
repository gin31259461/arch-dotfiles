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
| `installer.sh [-y]`                   | fzf group-select installer; calls `setup_<pkg>()` post-install |
| `cleanup.sh [-y]`                     | fzf task-select cleanup (pacman cache, orphans, journal, etc.) |

## Library Namespace (`~/.local/lib/dotfiles-arch/`)

| Path | Purpose |
| ---- | ------- |
| `config/dotfiles.toml`       | tracked path groups for `dotfiles.sh`           |
| `config/cleanup.toml`        | cleanup task labels, details, requirements      |
| `config/packages.d/*.toml`   | package group definitions for `installer.sh`    |
| `dotfiles-config.py`         | central TOML parser for scripts                 |
| `tui.sh`                     | shared terminal UI helpers                      |
| `core/*.sh`, `optional/*.sh` | package setup hooks with `setup()` functions    |

## Packages (`~/.local/lib/dotfiles-arch/config/packages.d/*.toml`)

Groups: core, shell, cli-tools, terminal, dm, files, audio, network, capture,
theming, fonts, input, gtk, utils, sync, self-hosted, apps, neovim, noctalia,
razer, amd, dev, docker, asus, msi.

TOML format:

```toml
[key]
label = "Display Label"
official = ["pacman-package"]
aur = ["aur-package"]
```

## Package Setup Functions (`~/.local/lib/dotfiles-arch/{core,optional}/*.sh`)

Auto-discovered by `installer.sh`.

Rules:

- Filename must match the package key (e.g. `sunshine.sh` → `setup()`).
- Setup packages via `*.sh -> setup()` after install for that package.

## Commit Convention

Structure: Header, optional Body, optional Footer.

```plain
<type>(<scope>): <subject>

<body>

<footer>
```

Rules:

- Header is brief, 50 chars or less, imperative mood, no period at end
- Body 72 chars wrapped, optional
- Footer for co-authors, references, etc., optional (this project not allow co-authors trailers)

Types:

- feat: new feature
- fix: bug fix
- docs: documentation only changes
- style: code formatting, no logic changes
- refactor: code refactoring
- perf: performance improvement
- test: test changes
- build: build system changes
- ci: CI configuration changes
- chore: other changes
