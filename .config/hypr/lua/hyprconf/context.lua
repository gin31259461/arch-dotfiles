local M = {}

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

M.home = os.getenv("HOME") or ""
M.config_dir = os.getenv("HYPR_CONFIG_DIR") or (M.home .. "/.config/hypr")
M.hypr_lua = "lua " .. shell_quote(M.config_dir .. "/lua/bin/hypr.lua")
M.main_mod = "SUPER"
M.term = "kitty"
M.files = "thunar"
M.search_engine = "https://www.google.com/search?q="
M.touchpad_device = "asue1209:00-04f3:319f-touchpad"
M.noctalia_shell = {
  enabled = true,
  command = "qs -c noctalia-shell",
}

return M
