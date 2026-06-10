local M = {}

local function clamp(value, min, max)
  if value < min then
    return min
  end
  if value > max then
    return max
  end
  return value
end

local function parse(value, fallback)
  local hex = tostring(value or ""):match("#?(%x%x%x%x%x%x)")
  if not hex and fallback then
    hex = tostring(fallback):match("#?(%x%x%x%x%x%x)")
  end
  hex = hex or "000000"

  return {
    r = tonumber(hex:sub(1, 2), 16),
    g = tonumber(hex:sub(3, 4), 16),
    b = tonumber(hex:sub(5, 6), 16),
  }
end

local function hex(color)
  return string.format(
    "#%02x%02x%02x",
    clamp(math.floor(color.r + 0.5), 0, 255),
    clamp(math.floor(color.g + 0.5), 0, 255),
    clamp(math.floor(color.b + 0.5), 0, 255)
  )
end

function M.normalize(value, fallback)
  return hex(parse(value, fallback))
end

function M.strip(value, fallback)
  return M.normalize(value, fallback):sub(2)
end

function M.rgb(value, fallback)
  return "rgb(" .. M.strip(value, fallback) .. ")"
end

function M.mix(left, right, amount)
  local a = parse(left)
  local b = parse(right)
  local weight = clamp(amount or 0.5, 0, 1)

  return hex({
    r = a.r + (b.r - a.r) * weight,
    g = a.g + (b.g - a.g) * weight,
    b = a.b + (b.b - a.b) * weight,
  })
end

function M.lighten(value, amount)
  return M.mix(value, "#ffffff", amount)
end

function M.darken(value, amount)
  return M.mix(value, "#000000", amount)
end

function M.luminance(value)
  local c = parse(value)
  local function channel(v)
    v = v / 255
    if v <= 0.03928 then
      return v / 12.92
    end
    return ((v + 0.055) / 1.055) ^ 2.4
  end

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
end

function M.contrast_text(value)
  return M.luminance(value) > 0.45 and "#000000" or "#ffffff"
end

function M.material(values)
  local result = {}

  result.surface = M.normalize(values.mSurface, "#000000")
  result.surface_variant = M.normalize(
    values.mSurfaceVariant,
    M.lighten(result.surface, 0.1)
  )
  result.shadow = M.normalize(values.mShadow, M.darken(result.surface, 0.25))
  result.on_surface = M.normalize(
    values.mOnSurface,
    M.contrast_text(result.surface)
  )
  result.on_surface_variant = M.normalize(
    values.mOnSurfaceVariant,
    M.mix(result.on_surface, result.surface_variant, 0.25)
  )
  result.primary = M.normalize(values.mPrimary, result.on_surface)
  result.secondary = M.normalize(values.mSecondary, result.primary)
  result.tertiary = M.normalize(values.mTertiary, result.secondary)
  result.error = M.normalize(values.mError, "#f38ba8")
  result.outline = M.normalize(
    values.mOutline,
    M.mix(result.surface_variant, result.on_surface, 0.35)
  )
  result.on_primary = M.normalize(
    values.mOnPrimary,
    M.contrast_text(result.primary)
  )
  result.on_secondary = M.normalize(
    values.mOnSecondary,
    M.contrast_text(result.secondary)
  )
  result.on_tertiary = M.normalize(
    values.mOnTertiary,
    M.contrast_text(result.tertiary)
  )
  result.on_error = M.normalize(values.mOnError, M.contrast_text(result.error))
  result.hover = M.normalize(values.mHover, M.lighten(result.tertiary, 0.08))
  result.on_hover = M.normalize(values.mOnHover, M.contrast_text(result.hover))

  return result
end

function M.wallust_palette(values)
  local c = M.material(values)
  local yellow = M.mix(c.tertiary, c.error, 0.34)
  local cyan = M.mix(c.primary, c.tertiary, 0.5)

  return {
    background = c.surface,
    foreground = c.on_surface,
    color0 = c.shadow,
    color1 = c.error,
    color2 = c.tertiary,
    color3 = yellow,
    color4 = c.primary,
    color5 = c.secondary,
    color6 = cyan,
    color7 = M.mix(c.on_surface, "#ffffff", 0.12),
    color8 = c.outline,
    color9 = M.lighten(c.error, 0.18),
    color10 = M.lighten(c.tertiary, 0.16),
    color11 = M.lighten(yellow, 0.18),
    color12 = M.lighten(c.primary, 0.16),
    color13 = M.lighten(c.secondary, 0.16),
    color14 = M.lighten(cyan, 0.16),
    color15 = M.lighten(c.on_surface, 0.25),
  }
end

return M
