#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  installer  ·  Interactive dotfile dependency installer
#  Arch Linux + Hyprland
#
#  Usage: installer.sh [--yes]
#    --yes   skip the final confirmation prompt
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES_LIB_DIR="${DOTFILES_LIB_DIR:-$HOME/.local/lib/dotfiles-arch}"

source "$DOTFILES_LIB_DIR/tui.sh"

PACKAGES_DIR="${PACKAGES_DIR:-$DOTFILES_LIB_DIR/config/packages.d}"
DOTFILES_CONFIG_PARSER="${DOTFILES_CONFIG_PARSER:-$DOTFILES_LIB_DIR/dotfiles-config.py}"

# ── Package helpers ───────────────────────────────────────────────────────────
is_installed() { pacman -Qi "$1" &>/dev/null; }

# count_installed "pkg1 pkg2 ..." → "installed/total"
count_installed() {
  local ins=0 tot=0
  local -a pkgs
  read -ra pkgs <<<"$1"
  for p in "${pkgs[@]}"; do
    [[ -z "$p" ]] && continue
    tot=$((tot + 1))
    if is_installed "$p"; then ins=$((ins + 1)); fi
  done
  printf '%d/%d' "$ins" "$tot"
}

# missing_pkgs "pkg1 pkg2 ..." → prints one missing package per line
missing_pkgs() {
  local -a pkgs
  read -ra pkgs <<<"$1"
  for p in "${pkgs[@]}"; do
    [[ -z "$p" ]] && continue
    if ! is_installed "$p"; then printf '%s\n' "$p"; fi
  done
}

# color_ratio "2/7" → fixed-width (8 visible chars) colored badge
# Padding is computed from char count (not bytes) — correct in a UTF-8 locale.
color_ratio() {
  local ratio="$1"
  local ins="${ratio%/*}" tot="${ratio#*/}"
  local text color
  if [[ "$ins" -eq "$tot" && "$tot" -gt 0 ]]; then
    text="${ratio} ✔"
    color="$GRN"
  elif [[ "$ins" -gt 0 ]]; then
    text="$ratio"
    color="$YLW"
  else
    text="$ratio"
    color="$RED"
  fi
  local pad=$((8 > ${#text} ? 8 - ${#text} : 0))
  printf '%s%s%s%*s' "$color" "$text" "$RST" "$pad" ''
}

# strip_ansi — remove ANSI escape codes from a string
strip_ansi() { sed 's/\x1b\[[0-9;]*m//g' <<<"$1"; }

# ── Group lookups ─────────────────────────────────────────────────────────────
declare -a PKG_GROUPS=()

load_package_groups() {
  [[ -d "$PACKAGES_DIR" ]] || die "Package config directory not found: $PACKAGES_DIR"
  [[ -f "$DOTFILES_CONFIG_PARSER" ]] || die "Config parser not found: $DOTFILES_CONFIG_PARSER"
  command -v python3 &>/dev/null || die "python3 is required to read package TOML files"

  local records
  if ! records="$(python3 "$DOTFILES_CONFIG_PARSER" packages "$PACKAGES_DIR")"; then
    exit 1
  fi

  local key label official aur
  while IFS='|' read -r key label official aur; do
    [[ -n "$key" ]] || continue
    PKG_GROUPS+=("$key|$label|$official|$aur")
  done <<<"$records"

  [[ ${#PKG_GROUPS[@]} -gt 0 ]] || die "No package groups configured"
}

_group_field() {
  local key="$1" field="$2" # field: 1=key 2=label 3=official 4=aur
  for g in "${PKG_GROUPS[@]}"; do
    IFS='|' read -r k l off aur <<<"$g"
    if [[ "$k" == "$key" ]]; then
      case "$field" in
      label) printf '%s' "$l" ;;
      official) printf '%s' "$off" ;;
      aur) printf '%s' "$aur" ;;
      esac
      return
    fi
  done
}

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner() {
  printf '\n'
  printf "${BOLD}${BLU}┌─────────────────────────────────────────────────────┐${RST}\n"
  printf "${BOLD}${BLU}│${RST}  ${BOLD}Dotfile Package Installer${RST}                          ${BOLD}${BLU}│${RST}\n"
  printf "${BOLD}${BLU}│${RST}  ${DIM}Arch Linux + Hyprland${RST}                              ${BOLD}${BLU}│${RST}\n"
  printf "${BOLD}${BLU}└─────────────────────────────────────────────────────┘${RST}\n"
  printf '\n'
}

# ── Prerequisite: yay ─────────────────────────────────────────────────────────
ensure_yay() {
  section "Checking prerequisites"
  if command -v yay &>/dev/null; then
    ok "yay AUR helper found  $(yay --version | head -1)"
    return
  fi
  warn "yay not found — building from AUR..."
  command -v git &>/dev/null || die "git is required to build yay: sudo pacman -S git base-devel"
  local tmp
  tmp=$(mktemp -d)
  spin "Cloning yay from AUR…" \
    git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay" ||
    {
      rm -rf "$tmp"
      die "Failed to clone yay repository"
    }
  step "Building yay (may prompt for sudo password)…"
  (cd "$tmp/yay" && makepkg -si --noconfirm) ||
    {
      rm -rf "$tmp"
      die "Failed to build yay — check the output above"
    }
  rm -rf "$tmp"
  ok "yay installed"
}

# ── Build fzf lines ───────────────────────────────────────────────────────────
build_fzf_lines() {
  for g in "${PKG_GROUPS[@]}"; do
    IFS='|' read -r key label official aur <<<"$g"
    local all="${official} ${aur}"
    local ratio cbadge
    ratio=$(count_installed "$all")
    cbadge=$(color_ratio "$ratio")
    local preview
    preview=$(printf '%s' "${official} ${aur}" |
      tr ' ' ',' | sed 's/^,//; s/,$//' | cut -c1-55)
    printf "%-12s  [%s]  ${BOLD}%-28s${RST}  ${DIM}%s${RST}\n" \
      "$key" "$cbadge" "$label" "$preview"
  done
}

# ── Group selection: fzf or numbered fallback ─────────────────────────────────
declare -a SELECTED_KEYS=()

select_groups() {
  section "Select package groups"

  if command -v fzf &>/dev/null; then
    _select_fzf
  else
    _select_numbered
  fi
}

_select_fzf() {
  printf "${DIM}TAB = toggle  ·  ENTER = confirm  ·  CTRL-A = select all  ·  ESC = exit${RST}\n\n"
  local lines raw_selected
  lines=$(build_fzf_lines)

  raw_selected=$(
    printf '%s\n' "$lines" |
      fzf \
        --multi \
        --ansi \
        --no-sort \
        --height='~80%' \
        --border=rounded \
        --margin='1,0,0,0' \
        --prompt='Groups ❯ ' \
        --header=$'TAB = toggle  ·  ENTER = confirm  ·  CTRL-A = select all\n' \
        --bind='ctrl-a:toggle-all' \
        --color="$FZF_COLORS"
  ) || true # fzf exits 130 on ESC; || true prevents set -e from firing

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local key
    key=$(strip_ansi "$line" | awk '{print $1}')
    [[ -n "$key" ]] && SELECTED_KEYS+=("$key")
  done <<<"$raw_selected"
}

_select_numbered() {
  printf "${DIM}Enter numbers (e.g. 1 3 5-7), or ${RST}${BOLD}all${RST}\n\n"
  local i=1
  local -a menu_keys=()

  for g in "${PKG_GROUPS[@]}"; do
    IFS='|' read -r key label official aur <<<"$g"
    local ratio cbadge
    ratio=$(count_installed "${official} ${aur}")
    cbadge=$(color_ratio "$ratio")
    printf "${DIM}%2d)${RST}  %-12s  [%s]  %s\n" "$i" "$key" "$cbadge" "$label"
    menu_keys+=("$key")
    i=$((i + 1))
  done

  printf "\n${BOLD}Select:${RST} "
  read -r input

  [[ "${input,,}" == "all" ]] && {
    SELECTED_KEYS=("${menu_keys[@]}")
    return
  }

  local input_clean="${input//,/ }"
  for token in $input_clean; do
    if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      local lo="${BASH_REMATCH[1]}" hi="${BASH_REMATCH[2]}"
      for ((n = lo; n <= hi; n++)); do
        SELECTED_KEYS+=("${menu_keys[$((n - 1))]}")
      done
    elif [[ "$token" =~ ^[0-9]+$ ]]; then
      if ((token >= 1 && token <= ${#menu_keys[@]})); then
        SELECTED_KEYS+=("${menu_keys[$((token - 1))]}")
      else
        warn "Skipping $token: out of range (1-${#menu_keys[@]})"
      fi
    fi
  done
}

# ── Build install plan ────────────────────────────────────────────────────────
declare -a PLAN_OFFICIAL=() PLAN_AUR=()

build_plan() {
  section "Scanning installed packages"
  printf "${DIM}Checking %d group(s)…${RST}\n" "${#SELECTED_KEYS[@]}"

  local raw_off=() raw_aur=()

  for key in "${SELECTED_KEYS[@]}"; do
    local off aur
    off=$(_group_field "$key" official)
    aur=$(_group_field "$key" aur)

    if [[ -n "$off" ]]; then
      while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && raw_off+=("$pkg")
      done < <(missing_pkgs "$off")
    fi

    if [[ -n "$aur" ]]; then
      while IFS= read -r pkg; do
        [[ -n "$pkg" ]] && raw_aur+=("$pkg")
      done < <(missing_pkgs "$aur")
    fi
  done

  # De-duplicate
  if [[ ${#raw_off[@]} -gt 0 ]]; then
    mapfile -t PLAN_OFFICIAL < <(printf '%s\n' "${raw_off[@]}" | sort -u)
  fi
  if [[ ${#raw_aur[@]} -gt 0 ]]; then
    mapfile -t PLAN_AUR < <(printf '%s\n' "${raw_aur[@]}" | sort -u)
  fi
}

# ── Show plan ─────────────────────────────────────────────────────────────────
# Returns 0 if there's work to do, 1 if everything is already installed.
show_plan() {
  section "Installation plan"

  if [[ ${#PLAN_OFFICIAL[@]} -eq 0 && ${#PLAN_AUR[@]} -eq 0 ]]; then
    ok "All selected packages are already installed — nothing to do."
    return 1
  fi

  if [[ ${#PLAN_OFFICIAL[@]} -gt 0 ]]; then
    printf "\n${BOLD}Official (pacman) — %d package(s):${RST}\n" "${#PLAN_OFFICIAL[@]}"
    for p in "${PLAN_OFFICIAL[@]}"; do
      printf "${GRN}+${RST}  %s\n" "$p"
    done
  fi

  if [[ ${#PLAN_AUR[@]} -gt 0 ]]; then
    printf "\n${BOLD}AUR (yay) — %d package(s):${RST}\n" "${#PLAN_AUR[@]}"
    for p in "${PLAN_AUR[@]}"; do
      printf "${YLW}+${RST}  %s\n" "$p"
    done
  fi

  printf '\n'
  return 0
}

# ── Confirm & install ─────────────────────────────────────────────────────────
AUTO_YES=false

do_install() {
  if ! $AUTO_YES; then
    local total=$((${#PLAN_OFFICIAL[@]} + ${#PLAN_AUR[@]}))
    gum_confirm "Install $total package(s)?" || {
      warn "Aborted."
      exit 0
    }
  fi

  if [[ ${#PLAN_OFFICIAL[@]} -gt 0 ]]; then
    section "Installing official packages"
    note "Installing ${#PLAN_OFFICIAL[@]} official package(s)…"
    if sudo pacman -S --needed --noconfirm "${PLAN_OFFICIAL[@]}"; then
      ok "${#PLAN_OFFICIAL[@]} official package(s) installed"
    else
      warn "pacman exited with errors — some packages may not have installed"
    fi
  fi

  if [[ ${#PLAN_AUR[@]} -gt 0 ]]; then
    section "Installing AUR packages"
    note "Installing ${#PLAN_AUR[@]} AUR package(s)…"
    if yay -S --needed --noconfirm "${PLAN_AUR[@]}"; then
      ok "${#PLAN_AUR[@]} AUR package(s) installed"
    else
      warn "yay exited with errors — some AUR packages may not have installed"
    fi
  fi
}

# ── Summary ───────────────────────────────────────────────────────────────────
show_summary() {
  local total
  total=$((${#PLAN_OFFICIAL[@]} + ${#PLAN_AUR[@]}))
  section "Done"
  ok "$total package(s) installed successfully"
  note "Log out and back in for compositor/env changes to take effect."
  note "Run 'dotfiles.sh' to sync any updated configs."
  printf '\n'
}

# ── Extra Config ─────────────────────────────────────────────────────────

setup_file_for_key() {
  local key="$1" file
  for file in "$DOTFILES_LIB_DIR/core/$key.sh" "$DOTFILES_LIB_DIR/optional/$key.sh"; do
    [[ -f "$file" ]] && {
      printf '%s\n' "$file"
      return
    }
  done
}

group_has_installed_package() {
  local key="$1" official aur pkg
  official=$(_group_field "$key" official)
  aur=$(_group_field "$key" aur)

  for pkg in $official $aur; do
    is_installed "$pkg" && return 0
  done

  [[ -z "${official// /}" && -z "${aur// /}" ]]
}

run_setup_file() {
  local file="$1"

  (
    source "$file"

    if ! declare -f setup &>/dev/null; then
      warn "$(basename "$file") has no setup() function — skipping"
      return 0
    fi

    setup
  )
}

run_auto_setup() {
  section "Extra configuration"

  local ran_any=false
  declare -a setup_files=() setup_keys=()
  declare -A seen_keys=() seen_files=()

  for key in "${SELECTED_KEYS[@]}"; do
    local setup_file
    if setup_file=$(setup_file_for_key "$key") && group_has_installed_package "$key" && [[ -z "${seen_keys[$key]:-}" ]]; then
      setup_keys+=("$key")
      seen_keys[$key]=1
    fi

    local official aur pkg
    official=$(_group_field "$key" official)
    aur=$(_group_field "$key" aur)

    for pkg in $official $aur; do
      is_installed "$pkg" || continue
      [[ -n "${seen_keys[$pkg]:-}" ]] && continue
      setup_keys+=("$pkg")
      seen_keys[$pkg]=1
    done
  done

  for key in "${setup_keys[@]}"; do
    local file
    file=$(setup_file_for_key "$key") || continue
    [[ -n "${seen_files[$file]:-}" ]] && continue
    setup_files+=("$file")
    seen_files[$file]=1
  done

  for file in "${setup_files[@]}"; do
    local name
    name=$(basename "$file" .sh)
    spin "Running setup for $name" run_setup_file "$file"
    ran_any=true
  done

  local autologin_file
  if autologin_file=$(setup_file_for_key autologin); then
    local getty_tty1_dir="/etc/systemd/system/getty@tty1.service.d"
    if [[ -f "$getty_tty1_dir/override.conf" ]]; then
      ok "Autologin already configured — skipping"
      ran_any=true
    elif gum_confirm "Configure autologin for $USER?"; then
      spin "Running setup for autologin" run_setup_file "$autologin_file"
      ran_any=true
    fi
  fi

  if ! $ran_any; then
    note "No extra setup to run"
  fi

  ok "Extra configuration complete"
  return 0
}

extra_config() {
  run_auto_setup
}

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
  --yes | -y) AUTO_YES=true ;;
  --help | -h)
    printf 'Usage: %s [--yes]\n' "$(basename "$0")"
    printf '  --yes  skip confirmation prompt\n'
    exit 0
    ;;
  *) die "Unknown option: $arg" ;;
  esac
done

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  print_banner
  load_package_groups
  ensure_yay
  select_groups

  if [[ ${#SELECTED_KEYS[@]} -eq 0 ]]; then
    warn "No groups selected — nothing to do."
  else
    build_plan
    if show_plan; then
      do_install
      show_summary
    fi
  fi

  extra_config
}

main "$@"
