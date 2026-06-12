#!/usr/bin/env bash

grant_sunshine_cap_sys_admin() {
  local sunshine_path
  sunshine_path=$(command -v sunshine || true)

  if [[ -n "$sunshine_path" ]]; then
    sunshine_path=$(readlink -f "$sunshine_path")
  fi

  if [[ -z "$sunshine_path" ]]; then
    warn "Sunshine executable not found; skipping permission grant."
    return
  else
    if getcap "$sunshine_path" | grep -q "cap_sys_admin"; then
      ok "Sunshine already has cap_sys_admin permission"
      return
    else
      note "Granting cap_sys_admin to Sunshine at $sunshine_path"
      sudo setcap cap_sys_admin+p "$sunshine_path" || {
        warn "Failed to set cap_sys_admin on $sunshine_path. You may need to run 'sudo setcap cap_sys_admin+p $sunshine_path' manually."
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

setup() {
  grant_sunshine_cap_sys_admin
}
