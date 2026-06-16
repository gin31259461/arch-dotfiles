# Arch Linux and Hyprland Dotfiles

Bare git repo, used for managing dotfiles in `$HOME` with a separate git directory at `~/.dotfiles/`.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Scripts (`~/.local/bin/`)

- dotfiles.sh: for managing dotfiles
- bootstrap.sh: for fresh machine setup
- installer.sh: for installing packages from config
- cleanup.sh: for system maintenance tasks

## Library of Scripts (`~/.local/lib/dotfiles-arch/`)

- config/dotfiles.toml: path groups for `dotfiles.sh`
- config/cleanup.toml: cleanup task labels, details, requirements
- config/packages.d/*.toml: package group definitions for `installer.sh`
- dotfiles-config.py: central toml parser for scripts
- tui.sh: shared terminal ui helpers
- core/*.sh, optional/*.sh: package setup hooks with `setup()` functions

## Commit Rules

- Structure: header, body (optional), footer (optional).

    ```plain
    type(scope): subject -> header

    - content -> body
    - content
    - content

    footer
    ```

- Rules:
  - header is brief, 50 chars or less, imperative mood, no period at end
  - body 72 chars wrapped, optional
  - footer for co-authors, references, etc., optional (this project not allow co-authors trailers)
  - do not add any co-authors trailers

- Types:
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
