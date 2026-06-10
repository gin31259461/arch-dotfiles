local ctx = require("hyprconf.context")
local util = require("hyprconf.util")

local M = {}

local mod = ctx.main_mod
local bind = util.bind
local bind_exec = util.bind_exec
local raw_dispatch = util.raw_dispatch

-- luacheck: push ignore
local zoom_in =
  [[hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')"]]
local zoom_out =
  [[hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')"]]
-- luacheck: pop

local function applications()
  bind_exec(
    mod .. " + D",
    "application launcher",
    "qs -c noctalia-shell ipc call launcher toggle"
  )
  bind_exec(mod .. " + B", "open default browser", [[xdg-open "https://"]])
  bind_exec(
    mod .. " + A",
    "desktop overview",
    "$scriptsDir/session/overview-toggle.sh"
  )
  bind_exec(mod .. " + Return", "open terminal", "$term")
  bind_exec(mod .. " + E", "file manager", "$files")
  bind_exec(
    mod .. " + T",
    "global theme switcher",
    "$scriptsDir/display/theme-changer.sh"
  )
  bind_exec(
    mod .. " + SHIFT + T",
    "apply noctalia material theme",
    "$scriptsDir/display/noctalia-theme.sh"
  )
  bind_exec(mod .. " + H", "cheat sheet", "$scriptsDir/input/key-hints.sh")
  bind_exec(
    mod .. " + SHIFT + E",
    "quick settings",
    "$scriptsDir/rofi/quick-settings.sh"
  )
  bind_exec(mod .. " + ALT + E", "emoji menu", "$scriptsDir/rofi/rofi-emoji.sh")
  bind_exec(mod .. " + S", "web search", "$scriptsDir/rofi/rofi-search.sh")
  bind_exec(mod .. " + CTRL + S", "window switcher", "rofi -show window")
  bind_exec(
    mod .. " + ALT + O",
    "toggle blur",
    "$scriptsDir/display/change-blur.sh"
  )
  bind_exec(
    mod .. " + SHIFT + G",
    "toggle game mode",
    "$scriptsDir/session/game-mode.sh"
  )
  bind_exec(
    mod .. " + ALT + L",
    "toggle layout",
    "$scriptsDir/display/change-layout.sh"
  )
  bind_exec(
    mod .. " + ALT + V",
    "clipboard manager",
    "$scriptsDir/rofi/clip-manager.sh"
  )
  bind_exec(
    mod .. " + CTRL + R",
    "rofi theme selector",
    "$scriptsDir/rofi/rofi-theme-selector.sh"
  )
  bind_exec(
    mod .. " + CTRL + SHIFT + R",
    "rofi theme selector (modified)",
    "pkill rofi || true && $scriptsDir/rofi/rofi-theme-selector-modified.sh"
  )
  bind_exec(mod .. " + N", "open obsidian", "obsidian")
  bind_exec(
    mod .. " + SHIFT + M",
    "online music",
    "$scriptsDir/media/rofi-beats.sh"
  )
  bind(
    mod .. " + CTRL + O",
    raw_dispatch("setprop", "active opaque toggle"),
    "toggle active window opacity"
  )
  bind_exec(
    mod .. " + SHIFT + K",
    "search keybinds",
    "$scriptsDir/input/keybinds.sh"
  )
  bind_exec(
    mod .. " + SHIFT + A",
    "profile selector",
    "$scriptsDir/profile-selector/select.sh"
  )
  bind_exec(
    mod .. " + SHIFT + O",
    "change oh-my-zsh theme",
    "$scriptsDir/display/zsh-change-theme.sh"
  )
  bind_exec(
    "ALT_L + SHIFT_L",
    "switch keyboard layout globally",
    "$scriptsDir/input/keyboard-layout.sh switch",
    { locked = true, non_consuming = true }
  )
  bind_exec(
    "SHIFT_L + ALT_L",
    "switch keyboard layout per-window",
    "$scriptsDir/input/tak0-per-window-switch.sh",
    { locked = true, non_consuming = true }
  )
  bind_exec(mod .. " + ALT + C", "calculator", "$scriptsDir/rofi/rofi-calc.sh")
end

local function windows()
  bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen(), "fullscreen")
  bind(mod .. " + CTRL + F", raw_dispatch("fullscreen", "1"), "maximize window")
  bind(
    mod .. " + SPACE",
    hl.dsp.window.float({ action = "toggle" }),
    "toggle floating"
  )
  bind(
    mod .. " + ALT + SPACE",
    raw_dispatch("workspaceopt", "allfloat"),
    "float all windows"
  )
  bind_exec(
    mod .. " + SHIFT + Return",
    "dropdown terminal",
    "$scriptsDir/services/dropterminal.sh $term"
  )
  bind("CTRL + ALT + Delete", hl.dsp.exit(), "exit hyprland")
  bind(mod .. " + Q", hl.dsp.window.close(), "close window")
  bind_exec(
    mod .. " + SHIFT + Q",
    "kill process",
    "$scriptsDir/session/kill-active-process.sh"
  )
  bind_exec(
    "CTRL + ALT + L",
    "session menu",
    "qs -c noctalia-shell ipc call sessionMenu toggle"
  )

  bind(mod .. " + CTRL + D", hl.dsp.layout("removemaster"), "remove master")
  bind(mod .. " + I", hl.dsp.layout("addmaster"), "add master")
  bind(
    mod .. " + CTRL + Return",
    hl.dsp.layout("swapwithmaster"),
    "swap with master"
  )
  bind(mod .. " + SHIFT + I", hl.dsp.layout("togglesplit"), "toggle split")
  bind(mod .. " + P", hl.dsp.window.pseudo(), "toggle pseudo")
  bind(mod .. " + M", raw_dispatch("splitratio", "0.3"), "set split ratio 0.3")

  bind("ALT + tab", hl.dsp.window.cycle_next(), "cycle next window")
  bind("ALT + tab", hl.dsp.window.bring_to_top(), "bring active to top")
  bind(mod .. " + left", hl.dsp.focus({ direction = "left" }), "focus left")
  bind(mod .. " + right", hl.dsp.focus({ direction = "right" }), "focus right")
  bind(mod .. " + up", hl.dsp.focus({ direction = "up" }), "focus up")
  bind(mod .. " + down", hl.dsp.focus({ direction = "down" }), "focus down")
  bind(
    mod .. " + SHIFT + left",
    hl.dsp.window.resize({ x = -50, y = 0, relative = true }),
    "resize left",
    { repeating = true }
  )
  bind(
    mod .. " + SHIFT + right",
    hl.dsp.window.resize({ x = 50, y = 0, relative = true }),
    "resize right",
    { repeating = true }
  )
  bind(
    mod .. " + SHIFT + up",
    hl.dsp.window.resize({ x = 0, y = -50, relative = true }),
    "resize up",
    { repeating = true }
  )
  bind(
    mod .. " + SHIFT + down",
    hl.dsp.window.resize({ x = 0, y = 50, relative = true }),
    "resize down",
    { repeating = true }
  )
  bind(
    mod .. " + CTRL + left",
    hl.dsp.window.move({ direction = "left" }),
    "move left"
  )
  bind(
    mod .. " + CTRL + right",
    hl.dsp.window.move({ direction = "right" }),
    "move right"
  )
  bind(
    mod .. " + CTRL + up",
    hl.dsp.window.move({ direction = "up" }),
    "move up"
  )
  bind(
    mod .. " + CTRL + down",
    hl.dsp.window.move({ direction = "down" }),
    "move down"
  )
  bind(
    mod .. " + ALT + left",
    hl.dsp.window.swap({ direction = "left" }),
    "swap left"
  )
  bind(
    mod .. " + ALT + right",
    hl.dsp.window.swap({ direction = "right" }),
    "swap right"
  )
  bind(
    mod .. " + ALT + up",
    hl.dsp.window.swap({ direction = "up" }),
    "swap up"
  )
  bind(
    mod .. " + ALT + down",
    hl.dsp.window.swap({ direction = "down" }),
    "swap down"
  )

  bind(mod .. " + G", hl.dsp.group.toggle(), "toggle group")
  bind(mod .. " + Tab", raw_dispatch("changegroupactive", "f"), "next in group")
  bind(
    mod .. " + CTRL + tab",
    raw_dispatch("changegroupactive"),
    "change group active"
  )
  bind(
    mod .. " + SHIFT + Tab",
    raw_dispatch("changegroupactive", "b"),
    "prev in group"
  )
  bind(
    mod .. " + CTRL + K",
    hl.dsp.group.move_window("l"),
    "move into group left"
  )
  bind(
    mod .. " + CTRL + L",
    hl.dsp.group.move_window("r"),
    "move into group right"
  )
  bind(
    mod .. " + CTRL + H",
    raw_dispatch("moveoutofgroup"),
    "move out of group"
  )
end

local function workspaces()
  bind(mod .. " + tab", hl.dsp.focus({ workspace = "m+1" }), "next workspace")
  bind(
    mod .. " + SHIFT + tab",
    hl.dsp.focus({ workspace = "m-1" }),
    "previous workspace"
  )

  for i = 1, 10 do
    local keycode = 9 + i
    bind(
      mod .. " + code:" .. keycode,
      hl.dsp.focus({ workspace = i }),
      "workspace " .. i
    )
    bind(
      mod .. " + SHIFT + code:" .. keycode,
      hl.dsp.window.move({ workspace = i }),
      "move to workspace " .. i
    )
    bind(
      mod .. " + CTRL + code:" .. keycode,
      raw_dispatch("movetoworkspacesilent", tostring(i)),
      "move silently to workspace " .. i
    )
  end

  bind(
    mod .. " + SHIFT + bracketleft",
    hl.dsp.window.move({ workspace = "-1" }),
    "move to prev workspace"
  )
  bind(
    mod .. " + SHIFT + bracketright",
    hl.dsp.window.move({ workspace = "+1" }),
    "move to next workspace"
  )
  bind(
    mod .. " + CTRL + bracketleft",
    raw_dispatch("movetoworkspacesilent", "-1"),
    "move silently to prev workspace"
  )
  bind(
    mod .. " + CTRL + bracketright",
    raw_dispatch("movetoworkspacesilent", "+1"),
    "move silently to next workspace"
  )
  bind(
    mod .. " + CTRL + F9",
    raw_dispatch("movecurrentworkspacetomonitor", "l"),
    "workspace to left monitor"
  )
  bind(
    mod .. " + CTRL + F10",
    raw_dispatch("movecurrentworkspacetomonitor", "r"),
    "workspace to right monitor"
  )
  bind(
    mod .. " + CTRL + F11",
    raw_dispatch("movecurrentworkspacetomonitor", "u"),
    "workspace to upper monitor"
  )
  bind(
    mod .. " + CTRL + F12",
    raw_dispatch("movecurrentworkspacetomonitor", "d"),
    "workspace to lower monitor"
  )
  bind(
    mod .. " + mouse_down",
    hl.dsp.focus({ workspace = "e+1" }),
    "next workspace"
  )
  bind(
    mod .. " + mouse_up",
    hl.dsp.focus({ workspace = "e-1" }),
    "previous workspace"
  )

  bind(mod .. " + period", hl.dsp.layout("move +col"), "scroll columns right")
  bind(mod .. " + comma", hl.dsp.layout("move -col"), "scroll columns left")
  bind(
    mod .. " + ALT + period",
    hl.dsp.layout("colresize +0.1"),
    "resize column wider"
  )
  bind(
    mod .. " + ALT + comma",
    hl.dsp.layout("colresize -0.1"),
    "resize column narrower"
  )
  bind(
    mod .. " + CTRL + period",
    hl.dsp.layout("promote"),
    "promote window to own column"
  )
  bind(
    mod .. " + CTRL + ALT + period",
    hl.dsp.layout("swapcol r"),
    "swap column right"
  )
  bind(
    mod .. " + CTRL + ALT + comma",
    hl.dsp.layout("swapcol l"),
    "swap column left"
  )
  bind(mod .. " + ALT + F", hl.dsp.layout("fit visible"), "fit visible columns")
  bind(
    mod .. " + SHIFT + period",
    hl.dsp.layout("movewindowto r"),
    "move window to right column"
  )
  bind(
    mod .. " + SHIFT + comma",
    hl.dsp.layout("movewindowto l"),
    "move window to left column"
  )
  bind(
    mod .. " + CTRL + SHIFT + up",
    hl.dsp.layout("movewindowto u"),
    "move window up in column"
  )
  bind(
    mod .. " + CTRL + SHIFT + down",
    hl.dsp.layout("movewindowto d"),
    "move window down in column"
  )
  bind(
    mod .. " + CTRL + ALT + F",
    hl.dsp.layout("togglefit"),
    "toggle fit method"
  )
  bind(
    mod .. " + SHIFT + U",
    hl.dsp.window.move({ workspace = "special" }),
    "move to special"
  )
  bind(mod .. " + U", hl.dsp.workspace.toggle_special(), "toggle special")
end

local function devices()
  bind(
    mod .. " + mouse:272",
    hl.dsp.window.drag(),
    "move window",
    { mouse = true }
  )
  bind(
    mod .. " + mouse:273",
    hl.dsp.window.resize(),
    "resize window",
    { mouse = true }
  )
  bind_exec(mod .. " + ALT + mouse_down", "zoom in", zoom_in)
  bind_exec(mod .. " + ALT + mouse_up", "zoom out", zoom_out)

  bind_exec(
    "XF86AudioLowerVolume",
    "volume down",
    "qs -c noctalia-shell ipc call volume decrease",
    { locked = true, repeating = true }
  )
  bind_exec(
    "XF86AudioRaiseVolume",
    "volume up",
    "qs -c noctalia-shell ipc call volume increase",
    { locked = true, repeating = true }
  )
  bind_exec(
    "XF86AudioMicMute",
    "toggle mic mute",
    "qs -c noctalia-shell ipc call volume muteInput",
    { locked = true }
  )
  bind_exec(
    "XF86AudioMute",
    "toggle mute",
    "qs -c noctalia-shell ipc call volume muteOutput",
    { locked = true }
  )
  bind_exec("XF86Sleep", "sleep", "systemctl suspend", { locked = true })
  bind_exec(
    "XF86RFKill",
    "airplane mode",
    "$scriptsDir/session/airplane-mode.sh",
    { locked = true }
  )
  bind_exec(
    "XF86AudioPause",
    "pause",
    "$scriptsDir/media/media-ctrl.sh --pause",
    { locked = true }
  )
  bind_exec(
    "XF86AudioPlay",
    "play",
    "$scriptsDir/media/media-ctrl.sh --pause",
    { locked = true }
  )
  bind_exec(
    "XF86AudioNext",
    "next track",
    "$scriptsDir/media/media-ctrl.sh --nxt",
    { locked = true }
  )
  bind_exec(
    "XF86AudioPrev",
    "prev track",
    "$scriptsDir/media/media-ctrl.sh --prv",
    { locked = true }
  )
  bind_exec(
    "XF86AudioStop",
    "stop",
    "$scriptsDir/media/media-ctrl.sh --stop",
    { locked = true }
  )

  bind_exec(
    mod .. " + Print",
    "screenshot now",
    "$scriptsDir/session/screenshot.sh --now"
  )
  bind_exec(
    mod .. " + SHIFT + Print",
    "screenshot area",
    "$scriptsDir/session/screenshot.sh --area"
  )
  bind_exec(
    mod .. " + CTRL + Print",
    "screenshot in 5s",
    "$scriptsDir/session/screenshot.sh --in5"
  )
  bind_exec(
    mod .. " + CTRL + SHIFT + Print",
    "screenshot in 10s",
    "$scriptsDir/session/screenshot.sh --in10"
  )
  bind_exec(
    "ALT + Print",
    "screenshot active window",
    "$scriptsDir/session/screenshot.sh --active"
  )
  bind_exec(
    mod .. " + SHIFT + S",
    "screenshot (swappy)",
    "$scriptsDir/session/screenshot.sh --swappy"
  )

  bind_exec(
    "XF86MonBrightnessDown",
    nil,
    "qs -c noctalia-shell ipc call brightness decrease",
    { repeating = true }
  )
  bind_exec(
    "XF86MonBrightnessUp",
    nil,
    "qs -c noctalia-shell ipc call brightness increase",
    { repeating = true }
  )
  bind_exec("XF86Launch1", nil, "rog-control-center")
  bind_exec("XF86Launch3", nil, "asusctl led-mode -n")
  bind_exec("XF86Launch4", nil, "asusctl profile -n")
  bind_exec("XF86TouchpadToggle", nil, "$scriptsDir/services/touchpad.sh")
  bind_exec(mod .. " + F6", nil, "$scriptsDir/session/screenshot.sh --now")
  bind_exec(
    mod .. " + SHIFT + F6",
    nil,
    "$scriptsDir/session/screenshot.sh --area"
  )
  bind_exec(
    mod .. " + CTRL + F6",
    nil,
    "$scriptsDir/session/screenshot.sh --in5"
  )
  bind_exec(
    mod .. " + ALT + F6",
    nil,
    "$scriptsDir/session/screenshot.sh --in10"
  )
  bind_exec("ALT + F6", nil, "$scriptsDir/session/screenshot.sh --active")
end

function M.setup()
  applications()
  windows()
  workspaces()
  devices()
end

return M
