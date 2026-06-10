local ctx = require("hyprconf.context")

local M = {}

local vesktop_cmd = {
  "vesktop",
  "--start-minimized",
  "--enable-features=UseOzonePlatform",
  "--ozone-platform-hint=wayland",
  "--enable-wayland-ime",
}

local commands = {
  "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
  "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
  "uwsm app -- rog-control-center",
  "uwsm app -- mcontrolcenter",
  "uwsm app -- polychromatic-tray-applet",
  ctx.scripts_dir .. "/services/polkit.sh",
  "uwsm app -- nm-applet --indicator",
  "uwsm app -- blueman-applet",
  "ags",
  "qs -c overview",
  "wl-paste --type text --watch cliphist store",
  "wl-paste --type image --watch cliphist store",
  "uwsm app -- fcitx5",
  "sleep 3; uwsm app -- " .. table.concat(vesktop_cmd, " "),
  "uwsm app -- remmina -i",
  "uwsm app -- tailscale systray",
  ctx.scripts_dir .. "/services/dropterminal.sh kitty &",
  ctx.scripts_dir .. "/input/keybinds-layout-init.sh",
  ctx.scripts_dir .. "/display/change-layout.sh init",
}

local function autostart_commands()
  local result = {}
  for _, command in ipairs(commands) do
    result[#result + 1] = command
  end

  local noctalia = ctx.noctalia_shell or {}
  if noctalia.enabled then
    result[#result + 1] = noctalia.command or "qs -c noctalia-shell"
  end

  return result
end

function M.setup()
  hl.on("hyprland.start", function()
    hl.exec_cmd(ctx.config_dir .. "/initial-boot.sh", {})
    for _, command in ipairs(autostart_commands()) do
      hl.exec_cmd(command, {})
    end
  end)
end

return M
