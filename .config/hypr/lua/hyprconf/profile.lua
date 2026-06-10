local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

local M = {}

local categories = {
  animation = {
    user_file = "animations.lua",
    fallback = ctx.config_dir .. "/profiles/animation/default.lua",
  },
  monitor = {
    user_file = "monitors.lua",
    fallback = ctx.config_dir .. "/profiles/monitor/default.lua",
  },
}

local function warn(message)
  print("[WARN] " .. message)
end

local function category_config(category)
  return categories[category]
    or {
      user_file = category .. ".lua",
      fallback = ctx.config_dir .. "/profiles/" .. category .. "/default.lua",
    }
end

local function load_file(path, label)
  local ok, err = pcall(dofile, path)
  if ok then
    return true
  end

  warn("Unable to load " .. label .. " from " .. path .. ": " .. tostring(err))
  return false
end

function M.load(category, opts)
  opts = opts or {}

  local config = category_config(category)
  local user_path = ctx.config_dir .. "/lua/user/" .. config.user_file

  if util.file_exists(user_path) then
    return load_file(user_path, "user " .. category .. " profile")
  end

  local fallback = opts.fallback or config.fallback
  if fallback and util.file_exists(fallback) then
    return load_file(fallback, "default " .. category .. " profile")
  end

  if opts.default then
    opts.default()
    return true
  end

  return false
end

function M.apply_animation(spec)
  if spec.enabled ~= nil then
    hl.config({ animations = { enabled = spec.enabled } })
  end

  for _, curve in ipairs(spec.curves or {}) do
    hl.curve(curve.name, { type = "bezier", points = curve.points })
  end

  for _, animation in ipairs(spec.animations or {}) do
    hl.animation(animation)
  end
end

return M
