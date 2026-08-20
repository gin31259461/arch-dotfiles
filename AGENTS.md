# AGENTS.md

## Project Overview

This is a personal Arch Linux dotfiles repository for a Hyprland desktop.
`$HOME` is the work tree and `~/.dotfiles/` is the bare Git directory.

The repository owns the complete Homebase runtime configuration and its
workstation policy. It does not contain Homebase source code, and Homebase must
not seed or refresh these runtime files.

Read the relevant owner documentation before editing:

- `README.md` for the operator workflow and repository overview.
- `doc/graphical-session.md` for session ownership and credential-sensitive
  startup behavior.
- `~/.local/lib/homebase/AGENTS.md` before changing Homebase source.

## Repository Commands

Use the bare repository explicitly when the shell alias is unavailable:

```bash
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --short
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME ls-files
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME submodule status
```

After `.zshrc` loads, `dot` supplies the same Git context.

## Ownership and Important Paths

- `.config/homebase/config.toml` defines platform selection, repository,
  package-manager roles, and bootstrap package IDs.
- `.config/homebase/install.d/` owns install groups and package inventory.
- `.config/homebase/setup.toml` owns hook metadata, prerequisites, triggers,
  and direct command steps.
- `.config/homebase/cleanup.toml` owns task metadata, scanners, and direct
  command steps.
- `.config/homebase/sync.toml` is the only sync-path source of truth.
- `.local/libexec/homebase/setup/` owns idempotent workstation setup policy and
  its fake-command harness.
- `.local/libexec/homebase/cleanup/` owns cleanup targets, scanners, destructive
  behavior, and its fake-command harness.
- `.config/systemd/user/` owns custom session units and selected overrides.
- `.config/hypr` and `.config/nvim` are Git submodules.

Homebase executes the configured commands but must not know their hook/task
keys, service identities, registry paths, profile policy, or deletion targets.
Do not mirror dotfiles policy into Homebase Go code or documentation.

## Side-Effect Rules

- Do not run `hb bootstrap`, `hb install`, configured setup hooks, cleanup
  tasks, package managers, or `hb sync` unless the user explicitly requests
  live workstation changes.
- `hb validate` is read-only and is the preferred runtime-config check.
- Use temporary homes and fake commands for setup and cleanup tests.
- Do not reload or enable systemd user units merely to validate source or
  documentation.
- Do not change shell profiles, package databases, services, credentials, or
  dotfiles remotes during non-mutating validation.
- Never print, replace, commit, or stage secrets, encrypted credentials,
  database contents, tokens, or private keys.

## Runtime Configuration Rules

- Keep the runtime tree flat: `config.toml`, `install.d/*.toml`, `setup.toml`,
  `cleanup.toml`, and `sync.toml` directly under `.config/homebase/`.
- Preserve `schema_version = 1` in the root, setup, and cleanup catalogs.
- Runtime decoding is strict. Do not restore `homebase.toml`, `platforms/`,
  `packages.d`, `features`, or `actions`.
- `default_selected` affects interactive selection only.
- `explicit_only` install groups remain explicit opt-ins and cannot also be
  default-selected.
- Setup and cleanup steps are argument vectors. Put non-trivial shell behavior
  in versioned executables rather than TOML command strings.
- Keep scripts idempotent, fail-fast, and safe to rerun.
- Keep scanner operations read-only; cleanup scripts must validate exact
  targets before deletion.
- Run `hb validate` after changing any runtime TOML.

## Tracking Rules

Before `hb sync`, inspect both the configured paths and repository state:

```bash
sed -n '1,220p' ~/.config/homebase/sync.toml
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME status --short
```

`hb sync` stages configured deletions. Keep credentials, tokens, caches,
browser profiles, generated state, and machine-specific application data out of
tracked groups unless the user explicitly requests otherwise.

Do not track generated `graphical-session.target.wants/` symlinks. Track custom
unit sources and let the configured setup executable repair enablement.

## Graphical Session Rules

- `.zprofile` starts Hyprland through UWSM.
- `.local/libexec/homebase/setup/desktop-session.sh` is the sole active service
  inventory and reconciliation policy.
- Homebase owns only generic setup dispatch and must not contain unit names.
- Track custom unit sources; do not copy package-provided units into dotfiles.
- Keep system XDG autostart, tracked user units, and Hyprland autostart roles
  distinct so applications have one startup owner.
- Vicinae replaces Rofi; do not restore Rofi packages, configuration, keybinds,
  or theme-generation policy.

KeePassXC databases, encrypted systemd credentials, and
`.config/keepassxc/keepassxc.ini` are machine-local. The INI may contain
KeeShare private key material: inspect only specific required settings and
never print the full file. The retired Noctalia storage key is also untracked
recovery material and must not be displayed, replaced, or committed.

When changing session startup behavior, read `doc/graphical-session.md` and
keep its ownership flow consistent with the unit sources and
`desktop-session.sh`.

## Submodule Rules

Hyprland and Neovim are submodules at `.config/hypr` and `.config/nvim`.

When changing either submodule:

1. Commit inside the submodule repository.
2. Return to `$HOME`.
3. Stage the updated gitlink in the bare dotfiles repository.

Do not flatten submodules into ordinary tracked files. Leave unrelated dirty
submodule or worktree changes untouched.

## Editing Guidance

- Use `rg` for searches and `apply_patch` for manual edits.
- Follow `.editorconfig`: UTF-8, LF, final newline, two-space defaults for
  Markdown/TOML/JSON/YAML, and tabs where configured.
- Keep documentation concise and factual. Do not add badges, marketing copy,
  fake links, or unsupported commands.
- Keep cleanup metadata and command wiring in `cleanup.toml`; keep target and
  deletion policy in `.local/libexec/homebase/cleanup/`.
- Change graphical-session inventory only in `desktop-session.sh`; update unit
  sources and domain documentation when behavior changes.
- Keep secrets and generated files outside tracked path groups.

## Verification

For documentation changes:

```bash
markdownlint-cli2 README.md AGENTS.md doc/graphical-session.md
doc_placeholders="TO""DO|FIX""ME|T""BD|PLACE""HOLDER|change ""me|replace ""this"
rg -n "$doc_placeholders" README.md AGENTS.md doc/graphical-session.md
```

For runtime TOML changes:

```bash
hb validate
```

For dotfiles-owned setup and cleanup executables:

```bash
bash ~/.local/libexec/homebase/setup/test.sh
bash ~/.local/libexec/homebase/cleanup/test.sh
```

For graphical-session unit source changes, use the read-only verifier:

```bash
systemd-analyze --user verify ~/.config/systemd/user/*.service
systemctl --user --failed
```

Do not run the setup hook as a substitute for validation; it can reload the
user manager and enable or start services.

For Homebase source changes, follow its AGENTS.md and run the repository's
required `make check`, build, lint, and smoke targets as applicable.

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
