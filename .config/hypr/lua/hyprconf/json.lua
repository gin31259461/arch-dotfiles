local M = {}

function M.read(path)
  local file = assert(io.open(path, "r"))
  local content = file:read("*a")
  file:close()
  return content
end

local function decode_error(content, pos, message)
  error(
    string.format("invalid JSON at byte %d: %s", pos, message)
      .. "\n"
      .. content:sub(pos, pos + 40),
    0
  )
end

local function skip_space(content, pos)
  local _, next_pos = content:find("^[%s]*", pos)
  return (next_pos or pos - 1) + 1
end

local parse_value

local function parse_string(content, pos)
  if content:sub(pos, pos) ~= '"' then
    decode_error(content, pos, "expected string")
  end

  local result = {}
  pos = pos + 1

  while pos <= #content do
    local char = content:sub(pos, pos)

    if char == '"' then
      return table.concat(result), pos + 1
    end

    if char == "\\" then
      local escaped = content:sub(pos + 1, pos + 1)
      local replacements = {
        ['"'] = '"',
        ["\\"] = "\\",
        ["/"] = "/",
        b = "\b",
        f = "\f",
        n = "\n",
        r = "\r",
        t = "\t",
      }

      if replacements[escaped] then
        result[#result + 1] = replacements[escaped]
        pos = pos + 2
      elseif escaped == "u" then
        result[#result + 1] = "\\u" .. content:sub(pos + 2, pos + 5)
        pos = pos + 6
      else
        decode_error(content, pos, "invalid escape")
      end
    else
      result[#result + 1] = char
      pos = pos + 1
    end
  end

  decode_error(content, pos, "unterminated string")
end

local function parse_array(content, pos)
  local result = {}
  pos = skip_space(content, pos + 1)

  if content:sub(pos, pos) == "]" then
    return result, pos + 1
  end

  while true do
    local value
    value, pos = parse_value(content, pos)
    result[#result + 1] = value
    pos = skip_space(content, pos)

    local char = content:sub(pos, pos)
    if char == "]" then
      return result, pos + 1
    elseif char ~= "," then
      decode_error(content, pos, "expected ',' or ']'")
    end

    pos = skip_space(content, pos + 1)
  end
end

local function parse_object(content, pos)
  local result = {}
  pos = skip_space(content, pos + 1)

  if content:sub(pos, pos) == "}" then
    return result, pos + 1
  end

  while true do
    local key
    key, pos = parse_string(content, pos)
    pos = skip_space(content, pos)

    if content:sub(pos, pos) ~= ":" then
      decode_error(content, pos, "expected ':'")
    end

    result[key], pos = parse_value(content, skip_space(content, pos + 1))
    pos = skip_space(content, pos)

    local char = content:sub(pos, pos)
    if char == "}" then
      return result, pos + 1
    elseif char ~= "," then
      decode_error(content, pos, "expected ',' or '}'")
    end

    pos = skip_space(content, pos + 1)
  end
end

local function parse_number(content, pos)
  local value = content:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
  if not value or value == "" then
    decode_error(content, pos, "expected number")
  end
  return tonumber(value), pos + #value
end

function parse_value(content, pos)
  pos = skip_space(content, pos)
  local char = content:sub(pos, pos)

  if char == '"' then
    return parse_string(content, pos)
  elseif char == "{" then
    return parse_object(content, pos)
  elseif char == "[" then
    return parse_array(content, pos)
  elseif char == "t" and content:sub(pos, pos + 3) == "true" then
    return true, pos + 4
  elseif char == "f" and content:sub(pos, pos + 4) == "false" then
    return false, pos + 5
  elseif char == "n" and content:sub(pos, pos + 3) == "null" then
    return nil, pos + 4
  elseif char:match("[%-0-9]") then
    return parse_number(content, pos)
  end

  decode_error(content, pos, "unexpected token")
end

function M.decode(content)
  local value, pos = parse_value(content, 1)
  pos = skip_space(content, pos)
  if pos <= #content then
    decode_error(content, pos, "trailing content")
  end
  return value
end

function M.string_field(content, key)
  local value = M.decode(content)[key]
  return type(value) == "string" and value or nil
end

function M.object_string_field(content, object, key)
  local value = M.decode(content)[object]
  if type(value) ~= "table" then
    return nil
  end

  if key == "" then
    return type(value) == "string" and value or nil
  end

  value = value[key]
  return type(value) == "string" and value or nil
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
