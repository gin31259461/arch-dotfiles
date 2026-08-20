# AGENTS Instructions

## Project overview

This is a personal Arch Linux dotfiles repository for a Hyprland desktop.
`$HOME` is its worktree and `~/.dotfiles` is the bare Git directory. Git is
configured not to enumerate the rest of the home directory as untracked files.

The repository owns the complete Homebase runtime configuration and workstation
policy. Homebase source lives at `~/.local/lib/homebase` and owns only the core
CLI engine and platform mechanisms.

Read the document owned by the task before editing:

- `README.md` for operator workflows and current public behavior.
- `doc/graphical-session.md` for non-trivial session ownership and
  credential-sensitive startup behavior.
- `~/.local/lib/homebase/AGENTS.md` before changing Homebase source.
- The nested `AGENTS.md` inside `.config/hypr` or `.config/nvim` before editing
  either submodule.

## Ownership seam

| Owner | Source of truth |
| --- | --- |
| Runtime identity and package managers | `.config/homebase/config.toml` |
| Install groups and package inventory | `.config/homebase/install.d/*.toml` |
| Setup hook wiring | `.config/homebase/setup.toml` |
| Setup policy | `.local/libexec/homebase/setup/` |
| Cleanup task wiring | `.config/homebase/cleanup.toml` |
| Cleanup policy | `.local/libexec/homebase/cleanup/` |
| Sync paths | `.config/homebase/sync.toml` |
| Session inventory | Setup policy's `desktop-session.sh` |
| Custom user units | `.config/systemd/user/` |

Homebase executes configured commands but must not know workstation hook or
task keys, service identities, profile policy, package inventory, or deletion
targets. Do not mirror dotfiles policy into Homebase Go code, defaults,
examples, or documentation.

## Worktree and tracking rules

Use the bare repository explicitly when the `dot` alias is unavailable:

```bash
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" \
  status --short --untracked-files=no
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" ls-files
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" submodule status
```

- Preserve unrelated dirty files and submodules. Stage exact paths only.
- Do not scan all untracked files under `$HOME`; inspect intended paths
  explicitly.
- Treat `.config/homebase/sync.toml` as the only sync-path source of truth.
- `hb sync` stages configured deletions. Inspect the catalog and repository
  status before running it.
- Keep credentials, tokens, caches, browser profiles, generated state, and
  machine-local application data outside tracked groups unless explicitly
  requested.
- Do not track generated `graphical-session.target.wants/` symlinks.

Hyprland and Neovim are submodules at `.config/hypr` and `.config/nvim`. Commit
inside the submodule first, then stage only the updated gitlink in this bare
repository. Never flatten a submodule into ordinary tracked files.

## Side-effect rules

- Do not run bootstrap scripts, `hb bootstrap`, `hb install`, configured setup
  hooks, cleanup tasks, package managers, or `hb sync` unless the user
  explicitly requests live workstation changes.
- Treat setup hooks as live mutations and cleanup steps as destructive. Test
  them through the dotfiles-owned fake-command harnesses.
- Do not reload or enable services merely to validate source or documentation.
- Do not change shell profiles, package databases, credentials, remotes, or
  workstation state during validation.
- Never print, replace, commit, or stage secrets, encrypted credentials,
  database contents, tokens, or private keys.
- `hb validate` is read-only and is the preferred runtime-config check.

## Runtime configuration rules

- Keep the runtime tree flat: `config.toml`, `install.d/*.toml`, `setup.toml`,
  `cleanup.toml`, and `sync.toml` directly under `.config/homebase/`.
- Preserve `schema_version = 1` in the root, setup, and cleanup catalogs.
- Keep decoding strict. Do not restore retired `homebase.toml`, `platforms/`,
  `packages.d`, `features`, or `actions` shapes.
- `default_selected` affects interactive selection only.
- `explicit_only` groups remain explicit opt-ins and cannot also be
  default-selected.
- Keep setup and cleanup steps as argument vectors. Put non-trivial behavior in
  versioned executables rather than TOML command strings.
- Keep setup scripts idempotent and safe to rerun. Keep cleanup scanners
  read-only and validate exact targets before deletion.
- Run `hb validate` after changing runtime TOML.

## Graphical-session rules

- Read `doc/graphical-session.md` before changing session startup behavior.
- Keep `.zprofile` as the UWSM entrypoint for Hyprland.
- Change service inventory only in
  `.local/libexec/homebase/setup/desktop-session.sh`.
- Give each application exactly one startup owner. Do not copy
  package-provided units or add duplicate XDG, user-unit, and Hyprland paths.
- Track custom unit sources, not generated enablement symlinks.
- Preserve the KeePassXC, Secret Service, Noctalia, and tray-repair ordering
  documented in the domain document.
- Vicinae owns launching, clipboard history, window switching, file search,
  emoji selection, and dmenu behavior. Do not restore Rofi policy.

KeePassXC databases, encrypted systemd credentials,
`.config/keepassxc/keepassxc.ini`, and the retired Noctalia storage key are
machine-local. The KeePassXC INI can contain KeeShare private key material;
inspect only required keys and never print the whole file.

## Editing and documentation rules

- Use `rg` for searches and `apply_patch` for manual edits.
- Follow `.editorconfig`: UTF-8, LF, final newline, two-space defaults for
  Markdown, TOML, JSON, and YAML, with tabs where configured.
- Keep badges compact and verified, and link them to authoritative sites or
  relevant documentation. Avoid decorative badges, marketing copy, fake
  links, unsupported commands, and duplicated inventories.
- Keep current operator behavior in `README.md`, agent decisions here, and
  non-trivial session relationships in `doc/graphical-session.md`.
- Update source/config first, then update only the documentation whose public
  contract or ownership model changed.
- Update Homebase source and schema documentation together with dotfiles when
  changing their shared runtime contract.
- Do not retain completed plans or retired workflows as parallel architecture
  documentation.

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

For setup and cleanup executables:

```bash
bash ~/.local/libexec/homebase/setup/test.sh
bash ~/.local/libexec/homebase/cleanup/test.sh
```

For graphical-session unit changes, run the setup harness and the read-only
unit verifier:

```bash
bash ~/.local/libexec/homebase/setup/test.sh
systemd-analyze --user verify ~/.config/systemd/user/*.service
```

Do not run a live setup hook as a validation substitute. For Homebase source
changes, follow its AGENTS instructions and required Makefile checks.

Tests must protect a stable contract, schema invariant, destructive safety, or
non-trivial orchestration. Do not add coverage-only tests for trivial wrappers
or deleted implementation details.

## Agent infrastructure

- Issues and PRDs use GitHub Issues; follow `docs/agents/issue-tracker.md`.
- Triage label mappings live in `docs/agents/triage-labels.md`.
- Domain-document discovery rules live in `docs/agents/domain.md`.
