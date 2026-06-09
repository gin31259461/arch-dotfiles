local ctx = require("hyprconf.context")

local M = {}

function M.trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.split_csv(value)
  local fields = {}
  for field in value:gmatch("([^,]+)") do
    fields[#fields + 1] = M.trim(field)
  end
  return fields
end

function M.file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

function M.expand(command)
  return command
    :gsub("%$HOME", ctx.home)
    :gsub("%$scriptsDir", ctx.scripts_dir)
    :gsub("%$term", ctx.term)
    :gsub("%$files", ctx.files)
    :gsub("%$Search_Engine", ctx.search_engine)
end

function M.exec(command)
  return hl.dsp.exec_raw(M.expand(command))
end

function M.dispatch_exec(command)
  return function()
    hl.dispatch(M.exec(command))
  end
end

function M.bind(keys, dispatcher, description, opts)
  opts = opts or {}
  if description then
    opts.description = description
  end
  return hl.bind(keys, dispatcher, opts)
end

function M.bind_exec(keys, description, command, opts)
  return M.bind(keys, M.exec(command), description, opts)
end

function M.raw_dispatch(name, arg)
  local command = "hyprctl dispatch " .. name
  if arg and arg ~= "" then
    command = command .. " " .. arg
  end
  return M.exec(command)
end

return M
