#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  tui.sh  ·  Shared terminal UI helpers for dotfile scripts
#
#  Source this file; do not execute it directly:
#    source "$HOME/.local/lib/dotfiles-arch/tui.sh"
# ─────────────────────────────────────────────────────────────────────────────

# ── Palette ──────────────────────────────────────────────────────────────────
# Terminal colors stay quiet and readable; gum/fzf get the matching hex theme.
TUI_BG="#0d1117"
TUI_SURFACE="#161b22"
TUI_BORDER="#30363d"
TUI_FG="#c9d1d9"
TUI_BRIGHT="#f0f6fc"
TUI_MUTED="#8b949e"
TUI_ACCENT="#58a6ff"
TUI_ACCENT_2="#79c0ff"
TUI_OK="#3fb950"
TUI_WARN="#d29922"
TUI_ERR="#f85149"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; BLU=$'\e[34m'
  DIM=$'\e[2m'; BOLD=$'\e[1m'; RST=$'\e[0m'
  ACC=$'\e[38;5;75m'; MUT=$'\e[38;5;245m'
else
  RED=''; GRN=''; YLW=''; BLU=''; DIM=''; BOLD=''; RST=''
  ACC=''; MUT=''
fi

# ── gum theme ────────────────────────────────────────────────────────────────
# Use := so callers can override any individual style before sourcing this file.
: "${GUM_CONFIRM_PROMPT_FOREGROUND:=$TUI_ACCENT}"
: "${GUM_CONFIRM_SELECTED_FOREGROUND:=$TUI_BG}"
: "${GUM_CONFIRM_SELECTED_BACKGROUND:=$TUI_ACCENT}"
: "${GUM_CONFIRM_UNSELECTED_FOREGROUND:=$TUI_MUTED}"

: "${GUM_SPIN_SPINNER_FOREGROUND:=$TUI_ACCENT}"
: "${GUM_SPIN_TITLE_FOREGROUND:=$TUI_FG}"

: "${GUM_INPUT_CURSOR_FOREGROUND:=$TUI_ACCENT}"
: "${GUM_INPUT_PROMPT_FOREGROUND:=$TUI_ACCENT}"
: "${GUM_INPUT_HEADER_FOREGROUND:=$TUI_BRIGHT}"
: "${GUM_INPUT_PLACEHOLDER_FOREGROUND:=$TUI_MUTED}"

: "${GUM_WRITE_CURSOR_FOREGROUND:=$TUI_ACCENT}"
: "${GUM_WRITE_PROMPT_FOREGROUND:=$TUI_ACCENT}"
: "${GUM_WRITE_HEADER_FOREGROUND:=$TUI_BRIGHT}"
: "${GUM_WRITE_BASE_FOREGROUND:=$TUI_FG}"
: "${GUM_WRITE_PLACEHOLDER_FOREGROUND:=$TUI_MUTED}"
: "${GUM_WRITE_END_OF_BUFFER_FOREGROUND:=$TUI_SURFACE}"

: "${GUM_CHOOSE_CURSOR_FOREGROUND:=$TUI_BG}"
: "${GUM_CHOOSE_CURSOR_BACKGROUND:=$TUI_ACCENT}"
: "${GUM_CHOOSE_SELECTED_FOREGROUND:=$TUI_OK}"
: "${GUM_CHOOSE_HEADER_FOREGROUND:=$TUI_MUTED}"

export GUM_CONFIRM_PROMPT_FOREGROUND GUM_CONFIRM_SELECTED_FOREGROUND
export GUM_CONFIRM_SELECTED_BACKGROUND GUM_CONFIRM_UNSELECTED_FOREGROUND
export GUM_SPIN_SPINNER_FOREGROUND GUM_SPIN_TITLE_FOREGROUND
export GUM_INPUT_CURSOR_FOREGROUND GUM_INPUT_PROMPT_FOREGROUND
export GUM_INPUT_HEADER_FOREGROUND GUM_INPUT_PLACEHOLDER_FOREGROUND
export GUM_WRITE_CURSOR_FOREGROUND GUM_WRITE_PROMPT_FOREGROUND
export GUM_WRITE_HEADER_FOREGROUND GUM_WRITE_BASE_FOREGROUND
export GUM_WRITE_PLACEHOLDER_FOREGROUND GUM_WRITE_END_OF_BUFFER_FOREGROUND
export GUM_CHOOSE_CURSOR_FOREGROUND GUM_CHOOSE_CURSOR_BACKGROUND
export GUM_CHOOSE_SELECTED_FOREGROUND GUM_CHOOSE_HEADER_FOREGROUND

# ── fzf theme ────────────────────────────────────────────────────────────────
# Use as: fzf --color="$FZF_COLORS" ...
FZF_COLORS="bg:${TUI_BG},bg+:${TUI_SURFACE},gutter:${TUI_BG},fg:${TUI_FG},fg+:${TUI_BRIGHT},hl:${TUI_ACCENT},hl+:${TUI_ACCENT_2},prompt:${TUI_ACCENT},pointer:${TUI_OK},marker:${TUI_OK},spinner:${TUI_WARN},header:${TUI_MUTED},info:${TUI_ACCENT_2},border:${TUI_BORDER},separator:${TUI_BORDER},scrollbar:${TUI_BORDER}"
export FZF_COLORS

# ── Layout helpers ───────────────────────────────────────────────────────────
tui_columns() {
  local cols="${COLUMNS:-}"
  if [[ -z "$cols" ]] && command -v tput &>/dev/null; then
    cols=$(tput cols 2>/dev/null || true)
  fi
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80
  ((cols < 40)) && cols=40
  ((cols > 92)) && cols=92
  printf '%s' "$cols"
}

tui_rule() {
  local cols char="${1:-─}" out="" i
  cols=$(tui_columns)
  for ((i = 0; i < cols; i++)); do
    out+="$char"
  done
  printf '%s' "$out"
}

# ── UI helpers ───────────────────────────────────────────────────────────────
die() {
  printf "\n${RED}✗${RST}  ${BOLD}%s${RST}\n\n" "$*" >&2
  exit 1
}

ok() { printf "${GRN}✓${RST}  %s\n" "$*"; }
warn() { printf "${YLW}!${RST}  %s\n" "$*"; }
note() { printf "${MUT}%s${RST}\n" "$*"; }
step() { printf "${ACC}›${RST}  %s\n" "$*"; }

section() {
  printf "\n${BOLD}%s${RST}\n" "$*"
  printf "${MUT}%s${RST}\n\n" "$(tui_rule)"
}

banner() {
  local title="$1" subtitle="${2:-}"
  printf "\n${BOLD}${ACC}%s${RST}" "$title"
  [[ -n "$subtitle" ]] && printf "  ${MUT}%s${RST}" "$subtitle"
  printf "\n${MUT}%s${RST}\n\n" "$(tui_rule)"
}

# gum_confirm QUESTION — gum confirm if available, else readline y/N prompt.
# Returns 0 (yes) or 1 (no).
gum_confirm() {
  local question="$1"

  if command -v gum &>/dev/null && [[ -t 0 && -t 1 ]]; then
    printf "\n"
    gum confirm "$question"
    return
  fi

  if [[ ! -t 0 ]]; then
    warn "Cannot prompt without an interactive terminal: $question"
    return 1
  fi

  printf "${ACC}?${RST}  %s  ${DIM}[y/N]${RST} " "$question"
  local _yn
  read -r _yn
  [[ "${_yn,,}" =~ ^y(es)?$ ]]
}

# spin TITLE CMD [ARGS…] — run CMD with a gum spinner.
# Falls back to step+run when gum is absent or CMD is a shell function/builtin.
spin() {
  local title="$1"
  shift

  if command -v gum &>/dev/null \
    && [[ -t 1 ]] \
    && [[ "$(type -t "$1" 2>/dev/null)" == "file" ]]; then
    gum spin --spinner dot --title "$title" --show-error -- "$@"
  else
    step "$title"
    "$@"
  fi
}
