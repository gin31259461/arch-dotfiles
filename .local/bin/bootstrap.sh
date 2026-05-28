#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  bootstrap  ·  New machine setup for arch-dotfiles
#  Arch Linux + Hyprland
#
#  Usage:
#    bash <(curl -fsSL https://raw.githubusercontent.com/gin31259461/arch-dotfiles/main/.local/bin/bootstrap.sh)
#    bootstrap.sh [--yes|-y] [--repo <ssh-url>]
#
#    --yes              non-interactive — accept all defaults (skip optional steps)
#    --repo <ssh-url>   SSH URL of YOUR dotfiles repo (for non-default owners)
#                       accepts: user/repo | git@host:user/repo.git
#
#  Repo selection logic:
#    · ~/.dotfiles-repo (memory file) overrides the hardcoded defaults at startup.
#      This lets a fork owner curl-pipe their own bootstrap.sh and have it clone
#      the right repo automatically on any new machine that already has the file.
#    · No --repo, or --repo matches the effective default:
#        → SSH clone from your repo (HTTPS fallback if no key)
#    · --repo differs from the effective default:
#        → HTTPS clone of the effective default repo as base, then set your
#          SSH URL as the remote so you can push to your own repo
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Constants & defaults ──────────────────────────────────────────────────────
DEFAULT_REPO_SSH="git@github.com:gin31259461/arch-dotfiles.git"
DEFAULT_REPO_HTTPS="https://github.com/gin31259461/arch-dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO_FILE="$HOME/.dotfiles-repo"   # remembers current SSH remote URL
OPT_YES=false
OPT_REPO=""
# Working repo URLs — overwritten by resolve_repo_urls when --repo is given
REPO_SSH="$DEFAULT_REPO_SSH"
REPO_HTTPS="$DEFAULT_REPO_HTTPS"

# ── Bootstrap tui.sh if not yet deployed ─────────────────────────────────────
if [[ ! -f "$HOME/.local/lib/tui.sh" ]]; then
  _raw="${DEFAULT_REPO_HTTPS%.git}"
  _raw="https://raw.githubusercontent.com/${_raw#https://github.com/}/main/.local/lib/tui.sh"
  mkdir -p "$HOME/.local/lib"
  curl -fsSL "$_raw" -o "$HOME/.local/lib/tui.sh" \
    || { printf 'ERROR: failed to fetch tui.sh from %s\n' "$_raw" >&2; exit 1; }
  unset _raw
fi
# shellcheck source=../.local/lib/tui.sh
source "$HOME/.local/lib/tui.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) OPT_YES=true ;;
    --repo|-r)
      [[ -n "${2:-}" ]] || die "--repo requires a value"
      OPT_REPO="$2"
      shift ;;
    --help|-h)
      printf 'Usage: %s [--yes] [--repo <ssh-url>]\n  -y, --yes           non-interactive (accept all defaults)\n  -r, --repo SSH-URL  your dotfiles SSH remote\n                      accepts: user/repo | git@host:user/repo.git\n                      matches memory → SSH clone your repo\n                      new URL       → HTTPS clone default + set your SSH remote\n' \
        "$(basename "$0")"
      exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
  shift
done

# ── Load defaults from memory file ───────────────────────────────────────────
# ~/.dotfiles-repo (if present) overrides the hardcoded DEFAULT_REPO_* values
# so that a fork owner's bootstrap.sh clones the right repo on any new machine.
# --repo can still override further inside main().
if [[ -f "$DOTFILES_REPO_FILE" ]]; then
  _mem=$(< "$DOTFILES_REPO_FILE")
  if [[ -n "$_mem" ]]; then
    DEFAULT_REPO_SSH="$_mem"
    if [[ "$_mem" == git@github.com:* ]]; then
      _slug="${_mem#git@github.com:}"; _slug="${_slug%.git}"
      DEFAULT_REPO_HTTPS="https://github.com/${_slug}.git"
    else
      DEFAULT_REPO_HTTPS=""
    fi
    REPO_SSH="$DEFAULT_REPO_SSH"
    REPO_HTTPS="$DEFAULT_REPO_HTTPS"
  fi
  unset _mem _slug
fi
dot() { git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"; }

# ── Confirm prompt ────────────────────────────────────────────────────────────
# Returns 0 (yes) or 1 (no). --yes flag always answers yes.
confirm() {
  $OPT_YES && return 0
  gum_confirm "$1"
}

# ── Resolve repo URLs from user input ────────────────────────────────────────
# Sets REPO_SSH and REPO_HTTPS from a user/repo shorthand or SSH URL.
# Non-GitHub SSH hosts get REPO_HTTPS="" (no fallback).
resolve_repo_urls() {
  local input="$1"
  if [[ "$input" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    # Shorthand: user/repo — assumed GitHub
    REPO_SSH="git@github.com:${input%.git}.git"
    REPO_HTTPS="https://github.com/${input%.git}.git"
  elif [[ "$input" == git@github.com:* ]]; then
    local slug="${input#git@github.com:}"; slug="${slug%.git}"
    REPO_SSH="git@github.com:${slug}.git"
    REPO_HTTPS="https://github.com/${slug}.git"
  elif [[ "$input" == git@* ]]; then
    # Non-GitHub SSH host — SSH only
    REPO_SSH="$input"
    REPO_HTTPS=""
  else
    die "Unrecognised repo format: '$input'
Use one of:
  user/repo                          (GitHub shorthand)
  git@github.com:user/repo.git       (SSH)"
  fi
}

# ── Memory file helpers ───────────────────────────────────────────────────────
# ~/.dotfiles-repo stores the SSH URL this machine's dotfiles are pushed to.
read_stored_ssh() {
  [[ -f "$DOTFILES_REPO_FILE" ]] && cat "$DOTFILES_REPO_FILE" || true
}

save_ssh_url() {
  printf '%s\n' "$1" > "$DOTFILES_REPO_FILE"
}

# ── Prompt for custom SSH URL (interactive) ───────────────────────────────────
prompt_repo() {
  if command -v gum &>/dev/null; then
    printf '\n'
    gum input \
      --placeholder "git@github.com:youruser/arch-dotfiles.git  or  user/repo" \
      --header "Your dotfiles SSH URL" \
      --width 70
  else
    printf '\nYour dotfiles SSH URL\n'
    local _url
    read -rp "Enter SSH URL (git@github.com:user/repo.git): " _url
    printf '%s' "$_url"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  [[ -f /etc/arch-release ]] || die "This script targets Arch Linux only"

  printf "\n  ${BOLD}Dotfiles Bootstrap${RST}  ${DIM}Arch Linux · Hyprland${RST}\n"
  printf "  ${DIM}%s${RST}\n" "$(printf '─%.0s' {1..44})"

  # ── Prerequisites ───────────────────────────────────────────────────────────
  section "Prerequisites"
  local -a missing=()
  for pkg in git rsync base-devel fzf gum; do
    if pacman -Qi "$pkg" &>/dev/null; then
      ok "$pkg"
    else
      missing+=("$pkg")
    fi
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    spin "Installing: ${missing[*]}" sudo pacman -S --needed --noconfirm "${missing[@]}"
    ok "Prerequisites ready"
  fi

  # ── Clone & deploy ──────────────────────────────────────────────────────────
  section "Dotfiles repository"
  if [[ -d "$DOTFILES_DIR" ]]; then
    ok "Bare repo already present at $DOTFILES_DIR — skipping clone"
    # Ensure the memory file exists even when the repo was cloned manually
    if [[ ! -f "$DOTFILES_REPO_FILE" ]]; then
      local current_remote; current_remote=$(dot remote get-url origin 2>/dev/null || true)
      if [[ -n "$current_remote" ]]; then
        save_ssh_url "$current_remote"
        note "Saved existing remote to $DOTFILES_REPO_FILE ($current_remote)"
      fi
    fi
  else
    local stored_ssh; stored_ssh=$(read_stored_ssh)

    # ── Determine effective SSH URL (flag > interactive > stored > default) ──
    if [[ -n "$OPT_REPO" ]]; then
      resolve_repo_urls "$OPT_REPO"
    elif ! $OPT_YES; then
      local label="${stored_ssh:-$DEFAULT_REPO_SSH (default)}"
      if ! gum_confirm "Use dotfiles repo: ${label}?"; then
        local custom_repo; custom_repo=$(prompt_repo)
        [[ -n "$custom_repo" ]] || die "No repository provided"
        resolve_repo_urls "$custom_repo"
      elif [[ -n "$stored_ssh" ]]; then
        resolve_repo_urls "$stored_ssh"
      fi
    elif [[ -n "$stored_ssh" ]]; then
      # --yes, no --repo, but a stored URL exists → use it
      resolve_repo_urls "$stored_ssh"
    fi

    # ── Clone strategy ───────────────────────────────────────────────────────
    # new_ssh_remote = true when user wants a non-default SSH URL that this
    # machine hasn't seen before.  In that case we clone the default dotfiles
    # via HTTPS (as a base) and wire the user's SSH URL as the remote for
    # future pushes.  Otherwise we clone directly from REPO_SSH (or HTTPS
    # fallback when there are no SSH keys yet).
    local new_ssh_remote=false
    if [[ -n "$REPO_SSH" ]] \
       && [[ "$REPO_SSH" != "${stored_ssh:-}" ]] \
       && [[ "$REPO_SSH" != "$DEFAULT_REPO_SSH" ]]; then
      new_ssh_remote=true
    fi

    local clone_url
    if $new_ssh_remote; then
      note "New SSH remote: $REPO_SSH"
      note "Base clone from default: $DEFAULT_REPO_HTTPS"
      clone_url="$DEFAULT_REPO_HTTPS"
    elif [[ -n "$REPO_SSH" && "$REPO_SSH" == git@github.com:* ]] \
         && ! ssh -T git@github.com -o BatchMode=yes -o ConnectTimeout=5 &>/dev/null 2>&1; then
      warn "No SSH access to GitHub — using HTTPS"
      clone_url="${REPO_HTTPS:-$REPO_SSH}"
    else
      clone_url="${REPO_SSH:-$REPO_HTTPS}"
    fi
    [[ -n "$clone_url" ]] || die "No valid repository URL resolved"

    local tmp; tmp=$(mktemp -d)
    spin "Cloning $clone_url" \
      git clone --separate-git-dir="$DOTFILES_DIR" "$clone_url" "$tmp/dotfiles" \
      || { rm -rf "$tmp"; die "Clone failed — check URL and network"; }

    section "Deploying to \$HOME"
    spin "Copying files…" rsync --recursive --exclude '.git' "$tmp/dotfiles/" "$HOME/"
    rm -rf "$tmp"
    ok "Files deployed to $HOME"

    # ── Wire SSH remote & save memory ────────────────────────────────────────
    if $new_ssh_remote; then
      dot remote set-url origin "$REPO_SSH"
      ok "Remote origin → $REPO_SSH"
      # Bake the fork's URLs into the deployed bootstrap.sh so any subsequent
      # machine bootstrapped from this fork works without --repo.
      local bs="$HOME/.local/bin/bootstrap.sh"
      if [[ -f "$bs" ]]; then
        sed -i "s|^DEFAULT_REPO_SSH=.*|DEFAULT_REPO_SSH=\"$REPO_SSH\"|" "$bs"
        if [[ -n "$REPO_HTTPS" ]]; then
          sed -i "s|^DEFAULT_REPO_HTTPS=.*|DEFAULT_REPO_HTTPS=\"$REPO_HTTPS\"|" "$bs"
        fi
        ok "Updated DEFAULT_REPO_SSH in bootstrap.sh → $REPO_SSH"
      fi
    fi
    if [[ -n "$REPO_SSH" ]]; then
      save_ssh_url "$REPO_SSH"
      note "Saved SSH URL to $DOTFILES_REPO_FILE"
    fi
  fi

  # ── Configure ───────────────────────────────────────────────────────────────
  section "Configuration"

  dot config --local status.showUntrackedFiles no
  ok "status.showUntrackedFiles = no"

  # Ensure dot alias is present in .zshrc
  local alias_line="alias dot='git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'"
  if [[ -f "$HOME/.zshrc" ]] && grep -q 'alias dot=' "$HOME/.zshrc"; then
    ok "dot alias already in .zshrc"
  else
    printf '\n# dotfiles bare repo\n%s\n' "$alias_line" >> "$HOME/.zshrc"
    ok "dot alias added to .zshrc"
  fi

  # Make all bin scripts executable
  chmod +x "$HOME/.local/bin/"*.sh 2>/dev/null || true
  ok "Scripts in ~/.local/bin made executable"

  # ── Submodules ──────────────────────────────────────────────────────────────
  section "Submodules"
  spin "Initialising submodules…" dot submodule update --init --recursive
  ok "Submodules ready"

  # ── Oh My Zsh ───────────────────────────────────────────────────────────────
  section "Oh My Zsh"
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "Oh My Zsh already installed"
  elif confirm "Install Oh My Zsh? (required by .zshrc)"; then
    step "Installing Oh My Zsh…"
    RUNZSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh My Zsh installed"

    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    spin "Installing zsh-autosuggestions…" \
      git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$custom/plugins/zsh-autosuggestions"

    spin "Installing zsh-syntax-highlighting…" \
      git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
      "$custom/plugins/zsh-syntax-highlighting"

    spin "Installing Powerlevel10k theme…" \
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$custom/themes/powerlevel10k"

    ok "Zsh plugins and theme ready"
  else
    warn "Skipped — .zshrc expects Oh My Zsh; install manually: https://ohmyz.sh"
  fi

  # ── Packages ────────────────────────────────────────────────────────────────
  section "Install packages"
  if [[ -f "$HOME/.local/bin/install-packages.sh" ]] && confirm "Run install-packages now?"; then
    "$HOME/.local/bin/install-packages.sh"
  elif [[ ! -f "$HOME/.local/bin/install-packages.sh" ]]; then
    note "install-packages.sh not found — skipping"
  else
    note "Run install-packages.sh later to install dotfile dependencies"
  fi

  # ── Done ────────────────────────────────────────────────────────────────────
  section "Done"
  ok "Bootstrap complete"
  note "Restart your shell or run: exec zsh"
  note "Use 'dot status' to inspect your dotfiles"
  note "Use 'dotfiles.sh' to sync config changes back to the repo"
  printf '\n'
}

main
