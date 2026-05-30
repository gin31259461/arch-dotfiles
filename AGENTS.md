# Arch Linux + Hyprland Dotfiles

Bare git repo — working tree is `$HOME`, bare repo at `~/.dotfiles/`.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

**Always use `dot`, never plain `git` in `$HOME`.** `dot status` hides untracked
files by design.

## Scripts (`~/.local/bin/`)

| Script | Purpose |
| ------ | ------- |
| `dotfiles.sh [-m "msg"]`              | Stage all tracked files, commit, push to `origin main`         |
| `bootstrap.sh [--yes] [--repo <url>]` | Fresh-machine setup: prereqs → clone → OMZ → packages          |
| `install-packages.sh [-y]`            | fzf group-select installer; calls `setup_<pkg>()` post-install |
| `cleanup.sh [-y]`                     | fzf task-select cleanup (pacman cache, orphans, journal, etc.) |

To track a new file: add it to the `dot add` block in `dotfiles.sh`.

## TUI (`~/.local/lib/tui.sh`)

Source in every new script. Sets Noctalia/Tokyo Night theme for gum + fzf and
exports:

| Helper | Behavior |
| ------ | -------- |
| `die MSG`               | stderr, red ✗, exit 1                    |
| `ok MSG`                | green ✔                                  |
| `warn MSG`              | yellow !                                 |
| `note MSG`              | dim secondary text                       |
| `step MSG`              | blue › progress                          |
| `section MSG`           | bold blue ◆ with leading blank line      |
| `gum_confirm Q`         | `gum confirm` or readline `y/N` fallback |
| `spin TITLE CMD [ARGS]` | gum spinner or `step` fallback           |

## Hyprland (`~/.config/hypr/`)

- `hyprland.conf` only sources — never edit it directly.
- Settings go in `conf.d/` (env, appearance, autostart, input, layout, misc,
  keybinds, window-rules, laptops, animations).
- `monitors.conf` and `workspaces.conf` are managed by `nwg-displays`.
- Scripts live in `scripts/{display,input,media,rofi,services,session}/` — 56
  scripts total.
- Initial boot hook: `initial-boot.sh` (re-trigger by deleting
  `.config/hypr/.initial_startup_done`).

## Packages (`~/.local/lib/packages.sh`)

28 groups (core, shell, terminal, bar, audio, network, capture, theming, fonts,
input, utils, wallpaper, dm, session, gtk, sync, self-hosted, apps, neovim,
noctalia, razer, amd, dev, docker, asus, msi, files, cleanup).

Format: `"key|Label|official pkgs|AUR pkgs"`

## Package Setup Functions (`~/.local/lib/{core,optional}/*.sh`)

Auto-discovered by `install-packages.sh`. Rules:

- Filename must match the package key (e.g. `sunshine.sh` → `setup_sunshine()`).
- Called automatically after install for that package.
- Current modules: `core/{autologin,sddm}.sh`,
  `optional/{docker,razer,sunshine}.sh`.

## Bootstrap Flow

1. Validate Arch Linux
2. Install prereqs (`git`, `gum`, `fzf`, `rsync`, `base-devel`)
3. Clone bare repo; optionally patch `bootstrap.sh` for fork ownership via
   `--repo`; SSH remote stored in `~/.dotfiles-repo`
4. Deploy files via `rsync`, set `status.showUntrackedFiles=no`, inject `dot`
   alias
5. Install Oh My Zsh + plugins (autosuggestions, syntax-highlighting,
   Powerlevel10k)
6. Offer to run `install-packages.sh`

## Rules

- Commit alway without co-author trailers
