local profile = require("hyprconf.profile")

local M = {}

function M.setup()
  profile.load("animation")
end

return M
