#!/usr/bin/env bash

SUNSHINE_PATH=$(readlink -f $(which sunshine))

grant_sunshine_cap_sys_admin() {
  if [[ -z "$SUNSHINE_PATH" ]]; then
    warn "Sunshine executable not found; skipping permission grant."
    return
  else
    if getcap "$SUNSHINE_PATH" | grep -q "cap_sys_admin"; then
      ok "Sunshine already has cap_sys_admin permission"
      return
    else
      info "Granting cap_sys_admin to Sunshine at $SUNSHINE_PATH"
      sudo setcap cap_sys_admin+p "$SUNSHINE_PATH" || {
        warn "Failed to set cap_sys_admin on $SUNSHINE_PATH. You may need to run 'sudo setcap cap_sys_admin+p $SUNSHINE_PATH' manually."
        return
      }
      ok "cap_sys_admin granted to Sunshine"
      systemctl --user enable sunshine.service || {
        warn "Failed to enable sunshine.service. You may need to run 'systemctl --user enable sunshine.service' manually."
        return
      }
      ok "sunshine.service enabled"
    fi
  fi
}

setup_sunshine() {
  grant_sunshine_cap_sys_admin
}
