# AGENTS.md

## Project Overview

This is a personal Arch Linux dotfiles repository for a Hyprland desktop.
It uses a bare Git repository: `$HOME` is the work tree and `~/.dotfiles/` is
the Git directory.

The repo stores the sole copy of Homebase platform runtime configuration,
desktop/app dotfiles, setup notes, local Codex agent profiles, and local agent
skills. It does not contain the Homebase source code. Homebase ships only its
global platform-selection default and never seeds or refreshes this repository's
platform TOML files.

Homebase runtime paths:

```text
~/.local/bin/hb
~/.local/lib/homebase/
```

Before changing Homebase itself, read:

```text
~/.local/lib/homebase/AGENTS.md
```

## Repository Commands

Check dotfiles status:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --short
```

List tracked files:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME ls-files
```

Inspect submodules:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME submodule status
```

After `.zshrc` is loaded, the `dot` alias is available:

```bash
dot status --short
```

## Homebase Workflow

Use current Homebase commands:

```bash
hb bootstrap
hb install
hb setup
hb cleanup
hb sync
```

Automation should pass `--yes` with explicit selections:

```bash
hb install --group apps --yes
hb install --all --yes
hb setup --hook desktop-session --yes
hb cleanup --task journal --yes
hb cleanup --all --yes
```

Do not restore the old shell bootstrap scripts or the removed
`~/.local/lib/dotfiles-arch/` library. If a repo-local bootstrap entry point is
needed, keep it as a small wrapper around the Homebase remote bootstrap.

## Important Paths

- `README.md` documents the operator workflow.
- `doc/` contains setup and maintenance notes. Some notes may predate
  Homebase; prefer current `hb` commands when instructions conflict.
- `.config/homebase/config.toml` selects the active platform. Current value:
  `[platform] active = "auto"`.
- `.config/homebase/platforms/archlinux/config.toml` defines the dotfiles repo,
  package managers, branch, and bootstrap packages.
- `.config/homebase/platforms/archlinux/install.d/` defines install groups.
- `.config/homebase/platforms/archlinux/cleanup.toml` defines cleanup tasks.
- `.config/homebase/platforms/archlinux/setup.toml` defines ordered setup hooks,
  prerequisites, automatic triggers, and dotfiles-owned commands.
- `.config/homebase/platforms/archlinux/sync.toml` is the sync source of truth.
- `.local/libexec/homebase/setup/` contains idempotent setup executables and a
  fake-command test harness. Homebase executes these commands but does not own
  their workstation policy.
- `.local/libexec/homebase/cleanup/` contains cleanup scanners, destructive
  executables, their shared helpers, and a fake-command test harness. Homebase
  executes these commands but does not own their paths or package policy.
- `.config/systemd/user/` contains tracked graphical-session units and
  selected service overrides; enablement is repaired through Homebase setup.
- Package-provided units are not tracked here. The dotfiles-owned
  `desktop-session.sh` executable owns the service inventory and reconciliation
  policy; `setup.toml` owns its Homebase hook metadata and triggers.
- `.config/hypr` and `.config/nvim` are Git submodules.
- `.agents/skills` and `.codex/agents` are tracked local agent configuration.

## Tracking Rules

Before running `hb sync`, review both the sync configuration and the bare repo
status:

```bash
sed -n '1,220p' ~/.config/homebase/platforms/archlinux/sync.toml
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --short
```

`hb sync` stages every configured path, including deletions. Keep
machine-local secrets, generated state, caches, browser profiles, credentials,
and account-specific tokens out of tracked path groups unless the user
explicitly asks to track them.

Tracked sync groups currently cover root docs and Git metadata, Homebase config,
Zsh files, GTK/Qt theming, app configs, user systemd overrides, and selected
OneDrive config files.

Do not track generated `graphical-session.target.wants/` symlinks. Track custom
unit source files and let `hb setup --hook desktop-session --yes` recreate
enablement links.

## Graphical Session Ownership

- `.zprofile` starts Hyprland through UWSM.
- This repository owns the active systemd user service inventory and its
  enable/start policy in `.local/libexec/homebase/setup/desktop-session.sh`.
- Homebase validates the generic setup schema and dispatches configured
  commands; it does not know workstation unit names or reconciliation policy.
- This repository owns the custom units for KeePassXC, Noctalia, Quickshell
  Overview, Polychromatic, Remmina, Tailscale systray, and Vesktop.
- `keepassxc.service` starts KeePassXC minimized, opens
  `~/.local/share/keepassxc/credentials.kdbx`, unlocks it through the untracked
  systemd encrypted credential
  `~/.local/share/keepassxc/keepassxc-password.cred`, and waits for the
  `credentials` Secret Service collection to report unlocked.
- `noctalia.service` starts only after the KeePassXC readiness check. It uses
  the default Secret Service storage key and keeps clipboard history disabled
  because Vicinae owns clipboard history.
- `keepassxc-tray-refresh.service` waits for Noctalia's StatusNotifierWatcher,
  then restarts KeePassXC once so the tray icon registers after the unlock-first
  startup phase. Keep this helper ordered after Noctalia; it is not part of the
  database-unlock path.
- `.config/keepassxc/keepassxc.ini` is machine-local and must not be tracked; it
  can contain KeeShare private key material. Inspect only the settings required
  for the current task and never print the complete file. The unattended
  Secret Service startup model requires `FdoSecrets/ConfirmAccessItem=false`
  so Noctalia storage lookup does not wait for an interactive access prompt.
  This disables per-item confirmation; keep Secret Service exposure limited to
  the required database group.
- The retired untracked
  `~/.local/share/noctalia/storage-key` may be needed to recover data encrypted
  under the former file-key configuration; never print, replace, or track it
  during routine validation.
- `.config/autostart/remmina-applet.desktop` is a tracked hidden marker. It
  prevents Remmina from recreating an active XDG autostart entry while
  `remmina-applet.service` remains the sole startup owner.
- The installed packages own `vicinae.service` and
  `hyprpolkitagent.service`; do not copy those units into this repository.
- NetworkManager, Blueman, and fcitx5 remain under system XDG autostart.
- The Hyprland submodule owns only compositor runtime autostart, currently the
  rainbow border helper. Do not duplicate session applications there.
- Vicinae replaces Rofi. Do not restore Rofi packages, configuration, keybinds,
  dependency sync, or Noctalia-to-Rasi theme generation.

## Submodule Rules

Hyprland and Neovim are submodules:

```text
.config/hypr
.config/nvim
```

When changing one of them:

1. Commit the change inside the submodule repository.
2. Return to `$HOME`.
3. Stage the updated gitlink in the bare dotfiles repo.

Do not flatten either submodule into ordinary tracked files. Leave unrelated
dirty submodule or worktree changes untouched.

## Editing Guidance

- Use `rg` for searches.
- Use `apply_patch` for manual edits.
- Keep documentation concise and factual.
- Do not add badges, marketing copy, fake demo links, or unsupported setup
  commands.
- Follow `.editorconfig`: UTF-8, LF, final newline, two-space defaults for
  Markdown/TOML/JSON/YAML, and tabs for Go and Make recipes where configured.
- Keep cleanup task metadata and command wiring in `cleanup.toml`, with complex
  scanner and deletion policy in `.local/libexec/homebase/cleanup/`. Do not
  mirror either into the Homebase source repository.
- Add or rename graphical-session applications in the dotfiles-owned
  `desktop-session.sh`; do not hardcode workstation unit names in Homebase Go
  code.
- Keep secrets and generated files out of tracked path groups.

## Verification

For dotfiles repo state:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --short
```

For documentation-only changes:

```bash
markdownlint-cli2 README.md AGENTS.md
doc_placeholders="TO""DO|FIX""ME|T""BD|PLACE""HOLDER|change ""me|replace ""this"
rg -n "$doc_placeholders" README.md AGENTS.md
```

For graphical-session unit changes:

```bash
systemd-analyze --user verify ~/.config/systemd/user/*.service
systemctl --user is-enabled \
  vicinae.service hyprpolkitagent.service keepassxc.service noctalia.service \
  quickshell-overview.service polychromatic-tray.service \
  remmina-applet.service tailscale-systray.service vesktop.service
systemctl --user --failed
```

The `is-enabled` and `--failed` checks are read-only. Do not run the Homebase
setup hook merely to validate documentation; it reloads the user manager and
can enable or start services.

Run `markdownlint-cli2` only when it is installed. If it is unavailable,
manually check Markdown headings, tables, fenced code blocks, and GitHub
admonitions.

For Homebase source changes, follow `~/.local/lib/homebase/AGENTS.md`. In
general, run from the Homebase repo:

```bash
make check && make build
```

Add `make lint` for Markdown changes and `make smoke` when command routing
changes.

For dotfiles-owned setup and cleanup executables:

```bash
bash ~/.local/libexec/homebase/setup/test.sh
bash ~/.local/libexec/homebase/cleanup/test.sh
```

## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues. See
`docs/agents/issue-tracker.md`.

### Triage labels

Triage uses the five default canonical labels. See
`docs/agents/triage-labels.md`.

### Domain docs

Domain documentation uses the single-context layout. See
`docs/agents/domain.md`.
