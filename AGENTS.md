# AGENTS.md

## Project Overview

This is a personal Arch Linux dotfiles repository for a Hyprland desktop.
It uses a bare Git repository: `$HOME` is the work tree and `~/.dotfiles/` is
the Git directory.

The repo stores Homebase runtime configuration, desktop/app dotfiles, setup
notes, local Codex agent profiles, and local agent skills. It does not contain
the Homebase source code.

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
hb cleanup
hb sync
```

Automation should pass `--yes` with explicit selections:

```bash
hb install --group apps --yes
hb install --all --yes
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
- `.config/homebase/homebase.toml` selects the active platform. Current value:
  `active_platform = "auto"`.
- `.config/homebase/platforms/archlinux/config.toml` defines the dotfiles repo,
  package managers, branch, and bootstrap basics.
- `.config/homebase/platforms/archlinux/packages.d/` defines installable
  package groups.
- `.config/homebase/platforms/archlinux/cleanup.toml` defines cleanup tasks.
- `.config/homebase/platforms/archlinux/sync.toml` is the sync source of truth.
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
- Prefer Homebase platform TOML files over hardcoded scripts when changing
  packages, cleanup tasks, or sync paths.
- Keep secrets and generated files out of tracked path groups.

## Verification

For dotfiles repo state:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --short
```

For documentation-only changes:

```bash
markdownlint README.md AGENTS.md
rg -n "TO""DO|FIX""ME|T""BD|PLACE""HOLDER|change ""me|replace ""this" README.md AGENTS.md
```

Run `markdownlint` only when it is installed. If it is unavailable, manually
check Markdown headings, tables, fenced code blocks, and GitHub admonitions.

For Homebase source changes, follow `~/.local/lib/homebase/AGENTS.md`. In
general, run from the Homebase repo:

```bash
make check && make build
```

Add `make lint` for Markdown changes and `make smoke` when command routing
changes.
