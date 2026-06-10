local M = {}

local modules = {
  "hyprconf.env",
  "hyprconf.runtime",
  "hyprconf.monitors",
  "hyprconf.autostart",
  "hyprconf.options",
  "hyprconf.gestures",
  "hyprconf.animations",
  "hyprconf.binds",
  "hyprconf.rules",
}

function M.setup()
  for _, name in ipairs(modules) do
    require(name).setup()
  end
end

return M
