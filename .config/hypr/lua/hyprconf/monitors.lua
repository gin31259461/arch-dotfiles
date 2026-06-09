local ctx = require("hyprconf.context")

local M = {}

M.setup = function()
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1",
  })

  hl.monitor({
    output = "",
    mode = "highrr",
    position = "auto",
    scale = "1",
  })

  hl.monitor({
    output = "",
    mode = "highres",
    position = "auto",
    scale = "1",
  })

  hl.monitor({
    output = "Virtual-1",
    mode = "1920x1080@60",
    position = "auto",
    scale = "1",
  })

  do
    local user_monitors = ctx.config_dir .. "/lua/hyprconf/monitors.lua"
    local ok, err = pcall(dofile, user_monitors)
    if
      not ok
      and err
      and tostring(err):find("No such file or directory", 1, true) == nil
    then
      print(
        "[WARN] Unable to load user monitor overrides from "
          .. user_monitors
          .. ": "
          .. tostring(err)
      )
    end
  end
end

return M
