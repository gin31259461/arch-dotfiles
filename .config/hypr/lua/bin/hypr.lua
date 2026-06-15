#!/usr/bin/env lua

local config_dir = (debug.getinfo(1, "S").source:sub(2):match("(.+)/../..$"))
  or ((os.getenv("HOME") or "") .. "/.config/hypr")

package.path = table.concat({
  config_dir .. "/lua/?.lua",
  config_dir .. "/lua/?/init.lua",
  package.path,
}, ";")

local capture = require("hyprconf.commands.capture")
local effects = require("hyprconf.commands.effects")
local layout = require("hyprconf.commands.layout")
local menus = require("hyprconf.commands.menus")
local profiles = require("hyprconf.commands.profiles")
local services = require("hyprconf.commands.services")
local session = require("hyprconf.commands.session")

---@type table<string, fun(...: string)>
local commands = {
  ["change-blur"] = layout.change_blur,
  ["change-layout"] = layout.change_layout,
  ["clip-manager"] = menus.clip_manager,
  ["game-mode"] = layout.game_mode,
  ["key-hints"] = menus.key_hints,
  ["keybinds"] = menus.keybinds,
  ["keybinds-layout-init"] = layout.keybinds_layout_init,
  ["kill-active"] = session.kill_active,
  ["kitty-themes"] = menus.kitty_themes,
  ["noctalia-theme"] = effects.noctalia_theme,
  ["overview"] = session.overview,
  ["polkit"] = services.polkit,
  ["portal-hyprland"] = services.portal_hyprland,
  ["profile-selector"] = profiles.profile_selector,
  ["quick-settings"] = menus.quick_settings,
  ["rainbow-border"] = effects.rainbow_border,
  ["rainbow-menu"] = effects.rainbow_menu,
  ["refresh"] = services.refresh,
  ["rofi-search"] = menus.rofi_search,
  ["rofi-theme"] = menus.rofi_theme,
  ["screenshot"] = capture.screenshot,
  ["sound"] = capture.sound,
  ["touchpad"] = session.touchpad,
  ["zsh-theme"] = menus.zsh_theme,
}

local function command_names()
  local names = {}
  for name in pairs(commands) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

local command = arg[1]
if not command or not commands[command] then
  io.stderr:write(
    "usage: hypr.lua <" .. table.concat(command_names(), "|") .. ">\n"
  )
  os.exit(1)
end

local command_args = {}
for index = 2, #arg do
  command_args[#command_args + 1] = arg[index]
end

commands[command](table.unpack(command_args))
