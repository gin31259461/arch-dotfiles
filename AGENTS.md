# AGENTS instructions

Bare git repo, used for managing dotfiles in `$HOME`
with a separate git directory at `~/.dotfiles/`.

```bash
alias dot='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

## Scripts (`~/.local/bin/`)

- dotfiles.sh: for managing dotfiles
- bootstrap.sh: for fresh machine setup
- installer.sh: for installing packages from config
- cleanup.sh: for system maintenance tasks

## Libraries (`~/.local/lib/dotfiles-arch/`)

- config/dotfiles.toml: path groups for `dotfiles.sh`
- config/cleanup.toml: cleanup task labels, details, requirements
- config/packages.d/*.toml: package group definitions for `installer.sh`
- dotfiles-config.py: central toml parser for scripts
- tui.sh: shared terminal ui helpers
- core/*.sh, optional/*.sh: package setup hooks with `setup()` functions
