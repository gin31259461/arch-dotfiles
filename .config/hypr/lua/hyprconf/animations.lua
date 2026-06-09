local M = {}

local curves = {
  wind = { { 0.05, 0.9 }, { 0.1, 1.05 } },
  winIn = { { 0.1, 1.1 }, { 0.1, 1.1 } },
  winOut = { { 0.3, -0.3 }, { 0, 1 } },
  liner = { { 1, 1 }, { 1, 1 } },
  overshot = { { 0.05, 0.9 }, { 0.1, 1.05 } },
  smoothOut = { { 0.5, 0 }, { 0.99, 0.99 } },
  smoothIn = { { 0.5, -0.5 }, { 0.68, 1.5 } },
}

local animations = {
  {
    leaf = "windows",
    enabled = true,
    speed = 6,
    bezier = "wind",
    style = "slide",
  },
  {
    leaf = "windowsIn",
    enabled = true,
    speed = 5,
    bezier = "winIn",
    style = "slide",
  },
  {
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    bezier = "smoothOut",
    style = "slide",
  },
  {
    leaf = "windowsMove",
    enabled = true,
    speed = 5,
    bezier = "wind",
    style = "slide",
  },
  { leaf = "border", enabled = true, speed = 1, bezier = "liner" },
  { leaf = "fade", enabled = true, speed = 3, bezier = "smoothOut" },
  { leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot" },
  {
    leaf = "workspacesIn",
    enabled = true,
    speed = 5,
    bezier = "winIn",
    style = "slide",
  },
  {
    leaf = "workspacesOut",
    enabled = true,
    speed = 5,
    bezier = "winOut",
    style = "slide",
  },
}

function M.setup()
  for name, points in pairs(curves) do
    hl.curve(name, { type = "bezier", points = points })
  end

  for _, animation in ipairs(animations) do
    hl.animation(animation)
  end
end

return M
