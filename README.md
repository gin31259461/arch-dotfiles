# Arch Hyprland Dotfiles

Personal Arch Linux dotfiles for a Hyprland desktop, managed through
[Homebase](https://github.com/gin31259461/homebase) and a bare Git repository.
This repository is the sole source of its Homebase runtime configuration;
Homebase does not ship or refresh a second copy.

![Desktop preview](assets/preview.png)

`$HOME` is the work tree and `~/.dotfiles/` is the Git directory. Use the `dot`
alias after `.zshrc` loads, or pass `--git-dir` and `--work-tree` explicitly.

## What It Manages

- Homebase runtime configuration under `.config/homebase/`.
- Package groups and dotfiles-owned setup and cleanup executables.
- Hyprland desktop, terminal, shell, theming, and application configuration.
- Custom graphical-session user units and selected service overrides.
- Hyprland and Neovim as Git submodules.

Homebase owns the reusable engine and platform mechanisms. This repository owns
package inventory, setup/cleanup policy, service identities, shell policy, and
sync paths.

## Requirements

- Arch Linux or Manjaro.
- A network connection and a user able to run the Homebase bootstrap.

The remote bootstrap installs the tools needed to build Homebase. Subsequent
bootstrap and package requirements come from `.config/homebase/config.toml` and
`install.d`; those files are the source of truth rather than this README.

## Get Started

Bootstrap Homebase and deploy this repository on a fresh Arch-family machine:

```bash
url=https://raw.githubusercontent.com/gin31259461/homebase/main/bootstrap
curl -fsSL "$url/archlinux.sh" | \
  bash -s -- --repo gin31259461/dotfiles-arch
```

To install every non-explicit package group after bootstrap:

```bash
url=https://raw.githubusercontent.com/gin31259461/homebase/main/bootstrap
curl -fsSL "$url/archlinux.sh" | \
  bash -s -- --repo gin31259461/dotfiles-arch --yes --install
```

Validate the complete runtime configuration without changing the workstation:

```bash
hb validate
```

Common operations:

```bash
hb install
hb setup
hb cleanup
hb sync -m "Update dotfiles"
```

For unattended runs, combine `--yes` with an explicit `--group`, `--hook`, or
`--task`, or use `--all` after reviewing the active configuration.

> [!IMPORTANT]
> `hb sync` stages every configured path, including deletions. Review
> `.config/homebase/sync.toml` and the bare-repository status before syncing.

## Configuration

The flat Homebase runtime tree is owned here:

```text
.config/homebase/
|-- config.toml
|-- install.d/*.toml
|-- setup.toml
|-- cleanup.toml
`-- sync.toml
```

Complex setup and cleanup policy lives under `.local/libexec/homebase/` and is
called by direct command vectors from the catalogs. The shell setup executable
owns Oh My Zsh, plugins, theme, and generated `hb` completion; Homebase does not
edit shell profiles.

Run `hb validate` after changing any runtime TOML. The
[Homebase README](https://github.com/gin31259461/homebase) documents the current
schema.

## Graphical Session

UWSM starts Hyprland from `.zprofile` and exposes
`graphical-session.target`. Startup is split by owner to prevent duplicate
processes:

| Owner | Responsibility |
| --- | --- |
| Package user units | Package-provided session services |
| Tracked user units | Dotfiles-owned desktop and tray applications |
| System XDG autostart | System-provided desktop applets and input method |
| Hyprland autostart | Compositor-local runtime effects only |

`.local/libexec/homebase/setup/desktop-session.sh` is the authoritative service
inventory and reconciliation policy. Do not duplicate that inventory in
Homebase or documentation.

The KeePassXC, Noctalia, tray-registration, and Secret Service startup model is
documented in [doc/graphical-session.md](doc/graphical-session.md).

Repair configured session enablement only when workstation changes are
intended:

```bash
hb setup --hook desktop-session --yes
```

## Daily Workflow

```bash
# Inspect repository state.
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --short

# Install a real configured group.
hb install --group cli-tools

# Run one configured cleanup task.
hb cleanup --task journal

# Sync without pushing.
hb sync -m "Update local config" --no-push
```

The `dot` alias provides the same bare-repository Git context after `.zshrc`
loads:

```bash
dot status --short
```

## Repository Layout

| Path | Purpose |
| --- | --- |
| `.config/homebase/` | Runtime configuration owned by this repository |
| `.local/libexec/homebase/` | Setup/cleanup policy and fake-command tests |
| `.config/systemd/user/` | Custom session units and selected overrides |
| `.config/hypr`, `.config/nvim` | Git submodules |
| `.config/quickshell/` | Desktop shell and overview configuration |
| `.config/kitty/`, `.config/ghostty/` | Terminal configuration |
| `doc/` | Workstation architecture, setup, and maintenance notes |

Older notes may describe retired workflows. Prefer current `hb` commands and
the runtime configuration when instructions conflict. Keep credentials,
tokens, generated caches, and machine-local application state outside tracked
sync groups.
