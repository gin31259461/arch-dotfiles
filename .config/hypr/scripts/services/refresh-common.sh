#!/usr/bin/env bash
# Shared helpers for refresh entrypoints.

_refresh_common_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=../lib/common.sh
source "$_refresh_common_dir/../lib/common.sh"
unset _refresh_common_dir

refresh_close_clients() {
  kill_by_name "$@"
}

refresh_apply_rainbow_border() {
  local rainbow_script="$HYPR_SCRIPTS_DIR/display/rainbow-border.sh"

  if rainbow_border_enabled && [[ -x "$rainbow_script" ]]; then
    "$rainbow_script" >/dev/null 2>&1 &
  fi
}
