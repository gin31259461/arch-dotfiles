local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

local M = {}

local function is_internal_panel(output)
  return output:match("^eDP%-")
    or output:match("^LVDS%-")
    or output:match("^DSI%-")
end

local function fallback()
  hl.monitor({
    output = "",
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
          if is_internal_panel(parts[1]) then
            spec = {
              output = parts[1],
              mode = "preferred",
              position = "auto",
              scale = tonumber(parts[4]) or parts[4] or "auto",
            }
          else
            spec.mirror = parts[6]
          end
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
