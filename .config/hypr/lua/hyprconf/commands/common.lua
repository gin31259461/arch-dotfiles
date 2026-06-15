local cli = require("hyprconf.cli")

local M = {}

M.bin_path = cli.config_dir .. "/lua/bin/hypr.lua"

function M.config(name)
  return cli.config_dir .. "/lua/config/" .. name .. ".toml"
end

function M.split_lines(value)
  local lines = {}
  for line in ((value or "") .. "\n"):gmatch("([^\n]*)\n") do
    if line ~= "" then
      lines[#lines + 1] = line
    end
  end
  return lines
end

function M.basename(path)
  return (path:gsub("/+$", ""):match("([^/]+)$") or path)
end

function M.without_suffix(value, suffix)
  if value:sub(-#suffix) == suffix then
    return value:sub(1, -#suffix - 1)
  end
  return value
end

function M.lua_cmd(args)
  return "lua " .. cli.shell_quote(M.bin_path) .. " " .. args
end

return M
