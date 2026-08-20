# Arch Hyprland Dotfiles

![Platform](https://img.shields.io/badge/platform-Arch%20Linux-1793D1?style=flat-square&logo=archlinux&logoColor=white)
![Desktop](https://img.shields.io/badge/desktop-Hyprland-58E1FF?style=flat-square)
![Homebase config](https://img.shields.io/badge/Homebase%20config-v1-222?style=flat-square)

Personal Arch Linux dotfiles for a Hyprland desktop. A bare Git repository
manages `$HOME` as its worktree and supplies the complete runtime policy for
[Homebase](https://github.com/gin31259461/homebase): packages, setup hooks,
cleanup tasks, sync paths, and the executables behind them.

![Desktop preview](assets/preview.png)

Homebase owns the reusable CLI engine and platform mechanisms. This repository
owns workstation policy under `~/.config/homebase`; Homebase does not ship or
refresh a second copy.

## Bootstrap

On Arch Linux or Manjaro, bootstrap Homebase and deploy this repository:

```bash
bootstrap_url=https://raw.githubusercontent.com/gin31259461/homebase/main/bootstrap
curl -fsSL "$bootstrap_url/archlinux.sh" | \
  bash -s -- --repo gin31259461/dotfiles-arch
```

Add `--yes --install` to install every non-explicit package group after the
repository is deployed:

```bash
bootstrap_url=https://raw.githubusercontent.com/gin31259461/homebase/main/bootstrap
curl -fsSL "$bootstrap_url/archlinux.sh" | \
  bash -s -- --repo gin31259461/dotfiles-arch --yes --install
```

Validate the deployed runtime configuration without changing the workstation:

```bash
hb validate
```

## Use Homebase

```bash
hb install
hb setup
hb cleanup
hb sync -m "Update dotfiles"
```

Interactive commands allow inspection and selection. For unattended runs, use
`--yes` with an explicit `--group`, `--hook`, or `--task`, or use `--all` only
after reviewing the active configuration.

> [!IMPORTANT]
> Install, setup, cleanup, and sync can modify the workstation. In particular,
> `hb sync` stages configured deletions. Review the selected operation and
> `.config/homebase/sync.toml` before using unattended flags.

## Runtime Configuration

The flat runtime tree under `.config/homebase/` is the executable source of
truth:

| Path | Responsibility |
| --- | --- |
| `config.toml` | Platform, repository, package managers, bootstrap packages |
| `install.d/*.toml` | Install groups and package inventory |
| `setup.toml` | Setup metadata, prerequisites, triggers, and command steps |
| `cleanup.toml` | Cleanup metadata, scanners, and command steps |
| `sync.toml` | Paths staged by `hb sync` |

Root, setup, and cleanup catalogs use schema version 1. Complex workstation
behavior lives in versioned executables under `.local/libexec/homebase/`; TOML
only selects and invokes those commands as argument vectors.

Run `hb validate` after changing any runtime TOML. The
[Homebase README](https://github.com/gin31259461/homebase) documents the public
CLI and config contract.

## Bare Repository Workflow

`$HOME` is the worktree and `~/.dotfiles` is the bare Git directory. After
`.zshrc` loads, the `dot` alias supplies both paths:

```bash
dot status --short --untracked-files=no
dot diff
```

Without the alias, pass the Git context explicitly:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" \
  status --short --untracked-files=no
```

Hyprland and Neovim are Git submodules at `.config/hypr` and `.config/nvim`.
Commit changes inside the owning submodule before recording the updated gitlink
in this repository.

## Graphical Session

UWSM starts Hyprland from `.zprofile` and exposes
`graphical-session.target`. Custom user units, package units, system XDG
autostart, and compositor-local effects each have distinct ownership so an
application has only one startup path.

The interaction between KeePassXC, Secret Service, Noctalia, and tray repair
is documented in [Graphical Session Ownership](doc/graphical-session.md).
`.local/libexec/homebase/setup/desktop-session.sh` remains the authoritative
service inventory and reconciliation policy.

Repair configured session enablement only when workstation changes are
intended:

```bash
hb setup --hook desktop-session --yes
```

## Validate Changes

Use the check that matches the changed owner:

```bash
# Runtime TOML
hb validate

# Dotfiles-owned setup and cleanup policy
bash ~/.local/libexec/homebase/setup/test.sh
bash ~/.local/libexec/homebase/cleanup/test.sh

# Documentation
markdownlint-cli2 README.md AGENTS.md doc/graphical-session.md
```

For graphical-session unit changes, also run the read-only unit verifier:

```bash
systemd-analyze --user verify ~/.config/systemd/user/*.service
```

These checks do not replace review of live setup, cleanup, or sync selections.
