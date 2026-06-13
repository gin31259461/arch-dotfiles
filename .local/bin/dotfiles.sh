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

# ── Stage files ───────────────────────────────────────────────────────────────

DOTFILES_CONFIG="${DOTFILES_CONFIG:-$HOME/.local/lib/dotfiles.toml}"
DOTFILES_LOADER="${DOTFILES_LOADER:-$HOME/.local/lib/read-dotfiles-toml.py}"

[[ -f "$DOTFILES_CONFIG" ]] || die "Dotfiles config not found: $DOTFILES_CONFIG"
[[ -f "$DOTFILES_LOADER" ]] || die "Dotfiles TOML loader not found: $DOTFILES_LOADER"

if ! DOTFILE_RECORDS="$(python3 "$DOTFILES_LOADER" "$DOTFILES_CONFIG")"; then
  exit 1
fi

mapfile -t DOTFILE_PATHS <<<"$DOTFILE_RECORDS"
[[ ${#DOTFILE_PATHS[@]} -gt 0 ]] || die "No dotfile paths configured"

dot add -- "${DOTFILE_PATHS[@]}"

# ── Commit and push ───────────────────────────────────────────────────────────

spin "Committing…" git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" commit -m "$COMMIT_MSG"
ok "Committed: $COMMIT_MSG"
spin "Pushing to origin…" git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" push origin main
ok "Pushed to origin main"
