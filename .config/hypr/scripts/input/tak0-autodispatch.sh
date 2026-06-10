#!/usr/bin/env bash
# Authoritative spawn dispatcher — forces all windows of an app launch onto a target workspace
#
# Usage: ./tak0-autodispatch.sh <workspace> [rule ...] -- <command>
#
# All window rules applied are TEMPORARY and removed on exit.
# Requirements: hyprctl, jq, pgrep/ps

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

LOGFILE="$(dirname "$0")/dispatch.log"

# Parse arguments: <workspace> [rule ...] -- <command>
TARGET_WS="$1"
shift || true

CAPTURE_RULES=()
CAPTURE_RULE_NAMES=()
while [[ "${1-}" != "--" && -n "${1-}" ]]; do
  CAPTURE_RULES+=("$1")
  shift || break
done
[[ "${1-}" == "--" ]] && shift

CMD="$*"

if [[ -z "$TARGET_WS" || -z "$CMD" ]]; then
  echo "Usage: $0 <workspace> [rule rule ...] -- <command>" >>"$LOGFILE"
  exit 1
fi

echo "=== Deploy '$CMD' → WS $TARGET_WS @ $(date) ===" >>"$LOGFILE"

rule_var_name() {
  local value="$1"
  value="${value//[^[:alnum:]_]/_}"
  printf 'tak0_capture_%s_%s\n' "$$" "$value"
}

parse_rule_match() {
  local rule="$1"
  local key="${rule%%:*}"
  local value="${rule#*:}"

  case "$key" in
    class) printf 'class\t%s\n' "$value" ;;
    initialClass) printf 'initial_class\t%s\n' "$value" ;;
    title) printf 'title\t%s\n' "$value" ;;
    initialTitle) printf 'initial_title\t%s\n' "$value" ;;
    *)
      echo "Unsupported capture rule for Lua window_rule: $rule" >>"$LOGFILE"
      return 1
      ;;
  esac
}

# Wait for Hyprland to be ready (silent early-autostart guard)
for _ in {1..50}; do
  hyprctl -j monitors >/dev/null 2>&1 && break
  sleep 0.1
done

# Remove all temporary rules on exit, crash, or signal
cleanup() {
  echo "Cleanup: removing temporary capture rules at $(date)" >>"$LOGFILE"
  hypr_disable_rule "tak0_capture_$$_initial_class" >>"$LOGFILE" 2>&1 || true
  for RULE_NAME in "${CAPTURE_RULE_NAMES[@]}"; do
    hypr_disable_rule "$RULE_NAME" >>"$LOGFILE" 2>&1 || true
  done
}
trap cleanup EXIT INT TERM ERR

# Temporarily force ALL new windows onto target workspace (catches fast helpers like gpu-process)
echo "Applying temporary initialWorkspace capture (initialClass:.*)" >>"$LOGFILE"
hypr_window_rule_initial_workspace "tak0_capture_$$_initial_class" "$TARGET_WS" "initial_class" ".*" \
  >>"$LOGFILE" 2>&1 || true

# Apply optional class-based pre-capture rules for Electron/Steam multi-process apps
for RULE in "${CAPTURE_RULES[@]}"; do
  IFS=$'\t' read -r MATCH_KEY MATCH_VALUE < <(parse_rule_match "$RULE") || continue
  RULE_NAME="$(rule_var_name "$RULE")"
  CAPTURE_RULE_NAMES+=("$RULE_NAME")
  echo "Applying temporary capture rule: $RULE" >>"$LOGFILE"
  hypr_window_rule_initial_workspace "$RULE_NAME" "$TARGET_WS" "$MATCH_KEY" "$MATCH_VALUE" \
    >>"$LOGFILE" 2>&1 || true
done

bash -c "$CMD" &
ROOT_PID=$!
echo "Root PID: $ROOT_PID" >>"$LOGFILE"

# Resolve canonical process name from /proc or command string
APP_NAME=""
for _ in {1..20}; do
  if [[ -r "/proc/$ROOT_PID/comm" ]]; then
    APP_NAME="$(tr -d '\0' <"/proc/$ROOT_PID/comm" 2>/dev/null || true)"
    break
  fi
  sleep 0.05
done

if [[ -z "$APP_NAME" ]]; then
  read -r -a cmd_toks <<<"$CMD"
  APP_NAME="$(basename "${cmd_toks[0]}")"
fi

echo "App gate name: $APP_NAME" >>"$LOGFILE"

sleep 1.5

# Release the broad capture rule now that the main process is running
echo "Releasing ultra-early wide capture" >>"$LOGFILE"
hypr_disable_rule "tak0_capture_$$_initial_class" >>"$LOGFILE" 2>&1 || true

# Recursively collect all descendant PIDs of a root process
get_descendants() {
  local root="$1"
  local all=("$root")
  local changed=1

  while ((changed)); do
    changed=0
    for p in "${all[@]}"; do
      for c in $(pgrep -P "$p" 2>/dev/null || true); do
        if [[ ! " ${all[*]} " =~ " $c " ]]; then
          all+=("$c")
          changed=1
        fi
      done
    done
  done

  echo "${all[@]}"
}

pid_matches_app() {
  local pid="$1"
  local comm
  comm="$(ps -p "$pid" -o comm= 2>/dev/null)" || return 1
  [[ "$comm" == "$APP_NAME" || "$comm" == "$APP_NAME"* ]]
}

# Supervision loop: move all matching windows to target workspace for 20 seconds
END_TIME=$((SECONDS + 20))
declare -A SEEN

while ((SECONDS < END_TIME)); do
  PIDS="$(get_descendants "$ROOT_PID")"

  while IFS=$'\t' read -r PID ADDR CLASS; do
    MATCH=0

    for TPID in $PIDS; do
      [[ "$PID" == "$TPID" ]] && MATCH=1 && break
    done

    pid_matches_app "$PID" && MATCH=1

    for RULE in "${CAPTURE_RULES[@]}"; do
      if [[ "$RULE" =~ class:\^\((.*)\)\$ ]]; then
        [[ "$CLASS" =~ ${BASH_REMATCH[1]} ]] && MATCH=1
      fi
    done

    if ((MATCH)) && [[ -z "${SEEN[$ADDR]-}" ]]; then
      echo "Placing window $ADDR (pid $PID, class $CLASS) → WS $TARGET_WS" >>"$LOGFILE"
      hypr_move_window "$TARGET_WS" "address:$ADDR" >>"$LOGFILE" 2>&1 || true
      SEEN[$ADDR]=1
    fi
  done < <(hyprctl clients -j | jq -r '.[] | [.pid, .address, .class] | @tsv')

  sleep 0.01
done

echo "=== Deploy finished: '$CMD' ===" >>"$LOGFILE"
exit 0
