local profile = require("hyprconf.profile")

local M = {}

M.setup = function()
  profile.load("monitor")
end

return M
