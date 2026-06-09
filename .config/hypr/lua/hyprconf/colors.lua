local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

local M = {}
local values = {}

local function load(path)
  if not util.file_exists(path) then
    return
  end

  for line in io.lines(path) do
    local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(rgb%([^%)]+%))")
    if name then
      values[name] = value
    end
  end
end

load(ctx.config_dir .. "/wallust/wallust-hyprland.conf")

local ok, noctalia = pcall(require, "hyprconf.generated.noctalia")
if ok then
  for name, value in pairs(noctalia) do
    values[name] = value
  end
end

function M.get(name, fallback)
  return values[name] or fallback
end

return M
