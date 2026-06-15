local profile = require("hyprconf.profile")

local M = {}

function M.setup()
  profile.load("monitor")
end

return M
