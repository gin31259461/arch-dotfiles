#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  cleanup  ·  Interactive Arch Linux system cleanup
#  Arch Linux + Hyprland
#
#  Usage: cleanup.sh [--yes]
#    --yes   skip confirmation prompts
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES_LIB_DIR="${DOTFILES_LIB_DIR:-$HOME/.local/lib/dotfiles-arch}"

# shellcheck source=../.local/lib/dotfiles-arch/tui.sh
source "$DOTFILES_LIB_DIR/tui.sh"

strip_ansi() { sed 's/\x1b\[[0-9;]*m//g' <<<"$1"; }

CLEANUP_CONFIG="${CLEANUP_CONFIG:-$DOTFILES_LIB_DIR/config/cleanup.toml}"
DOTFILES_CONFIG_PARSER="${DOTFILES_CONFIG_PARSER:-$DOTFILES_LIB_DIR/dotfiles-config.py}"

# ── Options ───────────────────────────────────────────────────────────────────
OPT_YES=false
for arg in "$@"; do
  case "$arg" in
  --yes) OPT_YES=true ;;
  --help | -h)
    printf 'Usage: %s [--yes]\n  --yes  skip confirmation prompts\n' \
      "$(basename "$0")"
    exit 0
    ;;
  *) die "Unknown option: $arg" ;;
  esac
done

# ── Size helpers ──────────────────────────────────────────────────────────────
# path_size PATH → "3.6G" | "n/a"
# Uses || true so a non-zero exit from du (e.g. unreadable files) doesn't
# also trigger the || branch after the caller's && … || expression.
path_size() {
  local size
  size=$(du -sh "$1" 2>/dev/null | awk '{print $1}') || true
  printf '%s' "${size:-n/a}"
}

# paccache_reclaimable → "1.2G" | "0B" | "n/a"
# Uses paccache --dryrun to report what -r would actually free.
paccache_reclaimable() {
  command -v paccache &>/dev/null || {
    printf 'n/a'
    return
  }
  local output freed
  output=$(paccache -d --nocolor 2>/dev/null) || true
  freed=$(printf '%s' "$output" | grep -oE '[0-9]+(\.[0-9]+)? [KMGT]iB' |
    tail -1 | tr -d ' ') || true
  printf '%s' "${freed:-0B}"
}

# journal_reclaimable → "42.3M" | "0B" | "n/a"
# Sums the sizes of journal files whose mtime is older than 2 weeks.
journal_reclaimable() {
  local cutoff total_bytes
  cutoff=$(date -d '2 weeks ago' +%s 2>/dev/null) || {
    printf 'n/a'
    return
  }
  total_bytes=$(
    find /var/log/journal -type f \( -name '*.journal' -o -name '*.journal~' \) \
      2>/dev/null |
      while IFS= read -r f; do
        local ft
        ft=$(stat -c '%Y' "$f" 2>/dev/null) || continue
        ((ft < cutoff)) && stat -c '%s' "$f" 2>/dev/null || true
      done |
      awk '{s+=$1} END {print (s+0)}'
  ) || true
  local b="${total_bytes:-0}"
  if ((b == 0)); then
    printf '0B'
  elif ((b < 1024 * 1024)); then
    printf '%dK' $((b / 1024))
  elif ((b < 1024 * 1024 * 1024)); then
    printf '%.1fM' \
      "$(awk "BEGIN{printf \"%.1f\", $b/1048576}")"
  else
    printf '%.1fG' \
      "$(awk "BEGIN{printf \"%.1f\", $b/1073741824}")"
  fi
}

# orphan_count → integer
orphan_count() { pacman -Qdtq 2>/dev/null | wc -l; }

# color_badge TEXT HINT → colored fixed-width 8-char badge (left-aligned)
# HINT: red | yel | grn | dim
color_badge() {
  local text="$1" hint="${2:-yel}"
  local color
  case "$hint" in
  red) color="$RED" ;; yel) color="$YLW" ;;
  grn) color="$GRN" ;; dim) color="$DIM" ;;
  esac
  local pad=$((8 > ${#text} ? 8 - ${#text} : 0))
  printf '%s%s%*s%s' "$color" "$text" "$pad" '' "$RST"
}

# task_badge KEY → colored fixed-width 8-char badge
task_badge() {
  local key="$1"
  local text hint
  case "$key" in
  pacman-cache)
    text=$(paccache_reclaimable)
    if [[ "$text" == "0B" || "$text" == "n/a" ]]; then
      hint=grn
    elif [[ "$text" == *G ]]; then
      hint=red
    else hint=yel; fi
    ;;
  yay-cache)
    text=$(path_size ~/.cache/yay/)
    if [[ "$text" == "n/a" ]]; then
      hint=grn
    elif [[ "$text" == *G ]]; then
      hint=red
    else hint=yel; fi
    ;;
  orphans)
    local n
    n=$(orphan_count)
    text="${n} pkgs"
    if [[ "$n" -eq 0 ]]; then
      hint=grn
    elif [[ "$n" -gt 20 ]]; then
      hint=red
    else hint=yel; fi
    ;;
  journal)
    text=$(journal_reclaimable)
    if [[ "$text" == "0B" || "$text" == "n/a" ]]; then
      hint=grn
    elif [[ "$text" == *G ]]; then
      hint=red
    else hint=yel; fi
    ;;
  npm-cache)
    text=$(path_size ~/.npm/)
    [[ "$text" == "n/a" ]] && hint=grn || hint=yel
    ;;
  thumbnails)
    text=$(path_size ~/.cache/thumbnails/)
    [[ "$text" == "n/a" ]] && hint=grn || hint=yel
    ;;
  esac
  color_badge "$text" "$hint"
}

# ── Task definitions ──────────────────────────────────────────────────────────
# TOML record format: "key|Label|Preview detail|Required command|Needs sudo"
declare -a CLEANUP_TASKS=()
declare -A CLEANUP_TASK_SUDO=()

load_cleanup_tasks() {
  [[ -f "$CLEANUP_CONFIG" ]] || die "Cleanup config not found: $CLEANUP_CONFIG"
  [[ -f "$DOTFILES_CONFIG_PARSER" ]] || die "Config parser not found: $DOTFILES_CONFIG_PARSER"
  command -v python3 &>/dev/null || die "python3 is required to read cleanup TOML"

  local records
  if ! records="$(python3 "$DOTFILES_CONFIG_PARSER" cleanup "$CLEANUP_CONFIG")"; then
    exit 1
  fi

  local key label detail requires needs_sudo
  while IFS='|' read -r key label detail requires needs_sudo; do
    [[ -n "$key" ]] || continue
    if [[ -n "$requires" ]] && ! command -v "$requires" &>/dev/null; then
      continue
    fi
    CLEANUP_TASKS+=("$key|$label|$detail")
    CLEANUP_TASK_SUDO["$key"]="$needs_sudo"
  done <<<"$records"

  [[ ${#CLEANUP_TASKS[@]} -gt 0 ]] || die "No cleanup tasks configured"
}

# ── fzf / numbered selection ──────────────────────────────────────────────────
declare -a SELECTED_KEYS=()

select_tasks() {
  section "Select cleanup tasks"
  if command -v fzf &>/dev/null; then
    _select_fzf
  else
    _select_numbered
  fi
}

build_fzf_lines() {
  for t in "${CLEANUP_TASKS[@]}"; do
    IFS='|' read -r key label detail <<<"$t"
    local badge
    badge=$(task_badge "$key")
    printf "%-14s  [%s]  ${BOLD}%-28s${RST}  ${DIM}%s${RST}\n" \
      "$key" "$badge" "$label" "$detail"
  done
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
        --prompt='Cleanup ❯ ' \
        --header=$'TAB = toggle  ·  ENTER = confirm  ·  CTRL-A = select all\n' \
        --bind='ctrl-a:toggle-all' \
        --color="$FZF_COLORS"
  ) || true

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local key
    key=$(strip_ansi "$line" | awk '{print $1}')
    [[ -n "$key" ]] && SELECTED_KEYS+=("$key")
  done <<<"$raw_selected"
}

_select_numbered() {
  printf "${DIM}Enter numbers (e.g. 1 3 5), or ${RST}${BOLD}all${RST}\n\n"
  local i=1
  local -a menu_keys=()

  for t in "${CLEANUP_TASKS[@]}"; do
    IFS='|' read -r key label _ <<<"$t"
    local badge
    badge=$(task_badge "$key")
    printf "${DIM}%2d)${RST}  %-14s  [%s]  %s\n" "$i" "$key" "$badge" "$label"
    menu_keys+=("$key")
    i=$((i + 1))
  done

  printf "\n${BOLD}Select:${RST} "
  read -r input

  [[ "${input,,}" == "all" ]] && {
    SELECTED_KEYS=("${menu_keys[@]}")
    return
  }

  local total=${#menu_keys[@]}
  for token in $input; do
    if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      local lo="${BASH_REMATCH[1]}" hi="${BASH_REMATCH[2]}"
      for ((n = lo; n <= hi; n++)); do
        if ((n >= 1 && n <= total)); then
          SELECTED_KEYS+=("${menu_keys[$((n - 1))]}")
        else
          warn "Number $n out of range (1–$total)"
        fi
      done
    elif [[ "$token" =~ ^[0-9]+$ ]]; then
      if ((token >= 1 && token <= total)); then
        SELECTED_KEYS+=("${menu_keys[$((token - 1))]}")
      else
        warn "Number $token out of range (1–$total)"
      fi
    fi
  done
}

# ── Show plan ─────────────────────────────────────────────────────────────────
show_plan() {
  [[ ${#SELECTED_KEYS[@]} -eq 0 ]] && {
    warn "Nothing selected."
    return 1
  }
  section "Cleanup plan"
  for key in "${SELECTED_KEYS[@]}"; do
    local label detail
    for t in "${CLEANUP_TASKS[@]}"; do
      IFS='|' read -r k l d <<<"$t"
      [[ "$k" == "$key" ]] && {
        label="$l"
        detail="$d"
        break
      }
    done
    printf "${BLU}·${RST}  ${BOLD}%-28s${RST}  ${DIM}%s${RST}\n" "$label" "$detail"
  done
}

# ── Run tasks ─────────────────────────────────────────────────────────────────
run_pacman_cache() {
  command -v paccache &>/dev/null ||
    die "paccache not found — install pacman-contrib"
  spin "Cleaning pacman cache…" sudo paccache -r
  ok "Pacman cache cleaned"
}

run_yay_cache() {
  command -v yay &>/dev/null || {
    warn "yay not found — skipping"
    return
  }
  spin "Clearing AUR build cache…" rm -rf "$HOME/.cache/yay/"
  ok "AUR build cache cleared"
}

run_orphans() {
  local -a pkgs
  mapfile -t pkgs < <(pacman -Qdtq 2>/dev/null || true)
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    ok "No orphaned packages found"
    return
  fi
  note "Packages to remove (${#pkgs[@]}): ${pkgs[*]}"
  if [[ "$OPT_YES" != true ]]; then
    gum_confirm "Remove ${#pkgs[@]} orphan(s)? (${pkgs[*]})" ||
      {
        warn "Skipped orphans"
        return
      }
  fi
  spin "Removing ${#pkgs[@]} orphan(s)…" sudo pacman -Rns --noconfirm "${pkgs[@]}"
  ok "Orphaned packages removed"
}

run_journal() {
  spin "Vacuuming systemd journal…" sudo journalctl --vacuum-time=2weeks
  ok "Journal vacuumed (kept last 2 weeks)"
}

run_npm_cache() {
  spin "Clearing npm cache…" npm cache clean --force
  ok "npm cache cleared"
}

run_thumbnails() {
  if [[ -d "$HOME/.cache/thumbnails/" ]]; then
    spin "Clearing thumbnail cache…" rm -rf "$HOME/.cache/thumbnails/"
    ok "Thumbnail cache cleared"
  else
    ok "Thumbnail cache already empty"
  fi
}

# Dispatch: run_<key with dashes → underscores>
run_task() {
  local key="$1"
  local fn="run_${key//-/_}"
  declare -f "$fn" &>/dev/null || die "No runner for task: $key"
  section "$key"
  "$fn"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  printf "\n${BOLD}${BLU}Arch Linux System Cleanup${RST}\n"
  load_cleanup_tasks
  select_tasks
  show_plan || exit 0

  if [[ "$OPT_YES" != true ]]; then
    gum_confirm "Proceed with cleanup?" || {
      warn "Aborted."
      exit 0
    }
  fi

  # Pre-warm sudo credentials for tasks that need root
  for key in "${SELECTED_KEYS[@]}"; do
    if [[ "${CLEANUP_TASK_SUDO[$key]:-false}" == true ]]; then
      sudo -v || die "sudo authentication failed"
      break
    fi
  done

  for key in "${SELECTED_KEYS[@]}"; do
    run_task "$key"
  done

  section "Done"
  ok "System cleanup complete"
}

main
