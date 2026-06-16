#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  dotfiles  ·  Sync dotfiles to the bare git repo
#
#  Usage: dotfiles.sh [-m "commit message"]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES_LIB_DIR="${DOTFILES_LIB_DIR:-$HOME/.local/lib/arch-dotfiles}"

# shellcheck source=../.local/lib/arch-dotfiles/tui.sh
source "$DOTFILES_LIB_DIR/tui.sh"

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

# ── Stage files ───────────────────────────────────────────────────────────────

DOTFILES_CONFIG="${DOTFILES_CONFIG:-$DOTFILES_LIB_DIR/config/dotfiles.toml}"
DOTFILES_CONFIG_PARSER="${DOTFILES_CONFIG_PARSER:-$DOTFILES_LIB_DIR/dotfiles-config.py}"

[[ -f "$DOTFILES_CONFIG" ]] || die "Dotfiles config not found: $DOTFILES_CONFIG"
[[ -f "$DOTFILES_CONFIG_PARSER" ]] || die "Config parser not found: $DOTFILES_CONFIG_PARSER"
command -v python3 &>/dev/null || die "python3 is required to read dotfiles TOML"

if ! DOTFILE_RECORDS="$(python3 "$DOTFILES_CONFIG_PARSER" dotfiles "$DOTFILES_CONFIG")"; then
  exit 1
fi

mapfile -t DOTFILE_PATHS <<<"$DOTFILE_RECORDS"
[[ ${#DOTFILE_PATHS[@]} -gt 0 ]] || die "No dotfile paths configured"

dot add --all -- "${DOTFILE_PATHS[@]}"

# ── Commit and push ───────────────────────────────────────────────────────────

spin "Committing…" git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" commit -m "$COMMIT_MSG"
ok "Committed: $COMMIT_MSG"
spin "Pushing to origin…" git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" push origin main
ok "Pushed to origin main"
