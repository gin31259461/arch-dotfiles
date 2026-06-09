local M = {}

local variables = {
  EDITOR = "nvim",
  GDK_BACKEND = "wayland,x11,*",
  QT_QPA_PLATFORM = "wayland;xcb",
  CLUTTER_BACKEND = "wayland",
  XDG_CURRENT_DESKTOP = "Hyprland",
  XDG_SESSION_DESKTOP = "Hyprland",
  XDG_SESSION_TYPE = "wayland",
  QT_AUTO_SCREEN_SCALE_FACTOR = "1",
  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1",
  QT_QPA_PLATFORMTHEME = "gtk3",
  QT_SCALE_FACTOR = "1",
  QT_QUICK_CONTROLS_STYLE = "org.hyprland.style",
  GDK_SCALE = "1",
  HYPRCURSOR_THEME = "Bibata-Modern-Ice",
  HYPRCURSOR_SIZE = "24",
  XCURSOR_THEME = "Bibata-Modern-Ice",
  XCURSOR_SIZE = "24",
  MOZ_ENABLE_WAYLAND = "1",
  ELECTRON_OZONE_PLATFORM_HINT = "auto",
  __GLX_VENDOR_LIBRARY_NAME = "mesa",
  GBM_BACKEND = "drm",
  QT_IM_MODULE = "fcitx",
  XMODIFIERS = "@im=fcitx",
  GLFW_IM_MODULE = "ibus",
  INPUT_METHOD = "fcitx",
  IMSETTINGS_MODULE = "fcitx",
  SDL_IM_MODULE = "fcitx",
}

function M.setup()
  for name, value in pairs(variables) do
    hl.env(name, value)
  end
end

return M
