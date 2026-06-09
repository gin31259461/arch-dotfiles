local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

local M = {}

local function fallback()
  hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "auto",
    scale = "auto",
  })
end

function M.setup()
  local path = ctx.config_dir .. "/monitors.conf"
  if not util.file_exists(path) then
    fallback()
    return
  end

  local loaded = false
  for line in io.lines(path) do
    local body = line:match("^%s*monitor%s*=%s*(.+)$")
    if body then
      local parts = util.split_csv(body)
      if parts[1] and parts[2] then
        local spec = {
          output = parts[1],
          mode = parts[2],
          position = parts[3] or "auto",
          scale = tonumber(parts[4]) or parts[4] or "auto",
        }

        if parts[5] == "mirror" and parts[6] then
          spec.mirror = parts[6]
        end

        hl.monitor(spec)
        loaded = true
      end
    end
  end

  if not loaded then
    fallback()
  end
end

return M
