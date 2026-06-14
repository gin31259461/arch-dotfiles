local M = {}

M.home = os.getenv("HOME")
M.config_dir = M.home .. "/.config/hypr"
M.scripts_dir = M.config_dir .. "/scripts"
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
