#!/usr/bin/env bash
# Authoritative spawn dispatcher — forces all windows of an app launch onto a target workspace
#
# Usage: ./tak0-autodispatch.sh <workspace> [rule ...] -- <command>
#
# All window rules applied are TEMPORARY and removed on exit.
# Requirements: hyprctl, jq, pgrep/ps

set -u

LOGFILE="$(dirname "$0")/dispatch.log"

# Parse arguments: <workspace> [rule ...] -- <command>
TARGET_WS="$1"
shift || true

CAPTURE_RULES=()
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

# Wait for Hyprland to be ready (silent early-autostart guard)
for _ in {1..50}; do
  hyprctl -j monitors >/dev/null 2>&1 && break
  sleep 0.1
done

# Remove all temporary rules on exit, crash, or signal
cleanup() {
  echo "Cleanup: removing temporary capture rules at $(date)" >>"$LOGFILE"
  hyprctl keyword windowrulev2 "unset, initialClass:.*" >>"$LOGFILE" 2>&1 || true
  for RULE in "${CAPTURE_RULES[@]}"; do
    hyprctl keyword windowrulev2 "unset, $RULE" >>"$LOGFILE" 2>&1 || true
  done
}
trap cleanup EXIT INT TERM ERR

# Temporarily force ALL new windows onto target workspace (catches fast helpers like gpu-process)
echo "Applying temporary initialWorkspace capture (initialClass:.*)" >>"$LOGFILE"
hyprctl keyword windowrulev2 \
  "initialWorkspace $TARGET_WS silent, initialClass:.*" \
  >>"$LOGFILE" 2>&1 || true

# Apply optional class-based pre-capture rules for Electron/Steam multi-process apps
for RULE in "${CAPTURE_RULES[@]}"; do
  echo "Applying temporary capture rule: $RULE" >>"$LOGFILE"
  hyprctl keyword windowrulev2 \
    "initialWorkspace $TARGET_WS silent, $RULE" \
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
hyprctl keyword windowrulev2 "unset, initialClass:.*" >>"$LOGFILE" 2>&1 || true

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
      hyprctl dispatch movetoworkspacesilent \
        "$TARGET_WS,address:$ADDR" >>"$LOGFILE" 2>&1 || true
      SEEN[$ADDR]=1
    fi
  done < <(hyprctl clients -j | jq -r '.[] | [.pid, .address, .class] | @tsv')

  sleep 0.01
done

echo "=== Deploy finished: '$CMD' ===" >>"$LOGFILE"
exit 0
