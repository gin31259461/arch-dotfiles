#!/usr/bin/env lua

local config_dir = os.getenv("HOME") .. "/.config/hypr"

package.path = table.concat({
  config_dir .. "/lua/?.lua",
  config_dir .. "/lua/?/init.lua",
  package.path,
}, ";")

local ok = require("hyprconf.theme.noctalia").apply()
os.exit(ok and 0 or 1)
