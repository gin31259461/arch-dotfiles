#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  dotfiles  ·  Sync dotfiles to the bare git repo
#
#  Usage: dotfiles.sh [-m "commit message"]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# shellcheck source=../.local/lib/tui.sh
source "$HOME/.local/lib/tui.sh"

dot() { git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"; }

# ── Options ───────────────────────────────────────────────────────────────────

COMMIT_MSG=""
while getopts ":m:h" opt; do
  case $opt in
  m) COMMIT_MSG="$OPTARG" ;;
  h)
    printf 'Usage: %s [-m "commit message"]\n' "$(basename "$0")"
    exit 0
    ;;
  \?) die "Unknown option: -$OPTARG" ;;
  :) die "Option -$OPTARG requires an argument" ;;
  esac
done

# ── Interactive commit message (gum write when -m is not provided) ────────────

if [[ -z "$COMMIT_MSG" ]]; then
  if command -v gum &>/dev/null; then
    printf "\n"
    COMMIT_MSG=$(gum write \
      --placeholder "Describe your changes…" \
      --header "Commit message" \
      --width 72 --height 6) || {
      warn "Aborted."
      exit 0
    }
  fi
  [[ -z "$COMMIT_MSG" ]] && COMMIT_MSG="sync dotfiles"
fi

cd "$HOME"

# ── stage files ──────────────────────────────────────────────────

# git & shell
dot add \
  README.md \
  .dotfiles-repo \
  doc \
  assets \
  .local/bin/dotfiles.sh \
  .local/bin/bootstrap.sh \
  .local/bin/install-packages.sh \
  .local/bin/cleanup.sh \
  .local/lib/core \
  .local/lib/optional \
  .local/lib/tui.sh \
  .local/lib/packages.sh \
  .gitconfig \
  .gitattributes \
  .gitmodules \
  .gitignore \
  .editorconfig \
  .agents \
  .claude/skills \
  AGENTS.md \
  CLAUDE.md

# zsh
dot add \
  .zshrc \
  .zprofile \
  .p10k.zsh

# gtk
dot add \
  .local/share/icons/Bibata-Modern-Ice \
  .config/gtk-3.0 \
  .config/gtk-4.0

# app configs
dot add \
  .config/nvim \
  .config/kitty \
  .config/electron-flags.conf \
  .config/hypr \
  .config/Kvantum \
  .config/quickshell \
  .config/rofi \
  .config/btop \
  .config/fastfetch \
  .config/qt5ct \
  .config/qt6ct \
  .config/swappy \
  .config/swaync \
  .config/wallust \
  .config/vesktop/settings \
  .config/vesktop/themes \
  .config/vesktop/settings.json \
  .config/cava \
  .config/ghostty \
  .config/waybar \
  .config/noctalia \
  .config/sunshine/sunshine.conf

# systemd user services
dot add \
  .config/systemd/user/sunshine.service.d

# OneDrive
dot add \
  .config/onedrive/config \
  .config/onedrive/sync_list

# ── Commit and push ───────────────────────────────────────────────────────────

spin "Committing…" git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" commit -m "$COMMIT_MSG"
ok "Committed: $COMMIT_MSG"
spin "Pushing to origin…" git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" push origin main
ok "Pushed to origin main"
