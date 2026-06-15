local ctx = require("hyprconf.context")
local toml = require("hyprconf.toml")

local M = {}

local autostart_config = ctx.config_dir .. "/lua/config/autostart.toml"

local function expand(command)
  return command:gsub("%$configDir", ctx.config_dir)
end

local function autostart_commands()
  local result = {}
  local ok, data = pcall(toml.read, autostart_config)
  if ok then
    for _, item in ipairs(data.command or {}) do
      if item.enabled ~= false and item.run then
        result[#result + 1] = expand(item.run)
      end
    end
  end

  local noctalia = ctx.noctalia_shell or {}
  if noctalia.enabled then
    result[#result + 1] = noctalia.command or "qs -c noctalia-shell"
  end

  return result
end

function M.setup()
  hl.on("hyprland.start", function()
    for _, command in ipairs(autostart_commands()) do
      hl.exec_cmd(command, {})
    end
  end)

  hl.on("config.reloaded", function()
    hl.exec_cmd(ctx.hypr_lua .. " refresh", {})
  end)

  hl.on("monitor.added", function()
    hl.exec_cmd("hyprctl reload", {})
  end)
end

return M
