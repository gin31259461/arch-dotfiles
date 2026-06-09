local M = {}

local function unescape(value)
  value = value:gsub('\\"', '"')
  value = value:gsub("\\\\", "\\")
  value = value:gsub("\\/", "/")
  value = value:gsub("\\n", "\n")
  value = value:gsub("\\r", "\r")
  value = value:gsub("\\t", "\t")
  return value
end

function M.read(path)
  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  return content
end

function M.string_field(content, key)
  local escaped = key:gsub("([^%w])", "%%%1")
  local value = content:match('"' .. escaped .. '"%s*:%s*"(.-)"')
  return value and unescape(value) or nil
end

function M.object_string_field(content, object, key)
  local escaped_object = object:gsub("([^%w])", "%%%1")
  local object_body = content:match('"' .. escaped_object .. '"%s*:%s*{(.-)}')
  if not object_body then
    return nil
  end
  return M.string_field(object_body, key)
end

function M.encode_object(values, order, indent)
  indent = indent or "    "
  local lines = { "{" }

  for index, key in ipairs(order) do
    local comma = index < #order and "," or ""
    local value = tostring(values[key] or "")
    value = value:gsub("\\", "\\\\"):gsub('"', '\\"')
    lines[#lines + 1] =
      string.format('%s"%s": "%s"%s', indent, key, value, comma)
  end

  lines[#lines + 1] = "}"
  return table.concat(lines, "\n") .. "\n"
end

return M
