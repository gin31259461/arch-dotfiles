#!/usr/bin/env bash
# Quick cheat sheet -- displays keybinds in a yad floating window (SUPER H)

# GDK BACKEND. Change to either wayland or x11 if having issues
BACKEND=wayland

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

# Close any existing instance before opening a new one
rofi_close_existing
kill_by_name yad

GDK_BACKEND=$BACKEND yad \
  --center \
  --title="Quick Cheat Sheet" \
  --no-buttons \
  --list \
  --column=Key: \
  --column=Description: \
  --column=Command: \
  --timeout-indicator=bottom \
  "ESC" "Close this window" "" \
  " = " "SUPER (Windows key)" "" \
  "" "" "" \
  " H" "This cheat sheet" "" \
  " SHIFT K" "Search keybinds" "(rofi)" \
  " SHIFT E" "Quick settings" "" \
  "" "" "" \
  " Return" "Terminal" "" \
  " SHIFT Return" "Dropdown terminal" "Q to close" \
  " B" "Browser" "(xdg default)" \
  " A" "Desktop overview" "" \
  " D" "Application launcher" "(noctalia-shell)" \
  " E" "File manager" "" \
  " N" "Obsidian" "" \
  " S" "Web search" "(rofi)" \
  " SHIFT T" "Apply noctalia Material theme" "" \
  " CTRL S" "Window switcher" "(rofi)" \
  " ALT V" "Clipboard manager" "(cliphist)" \
  " SHIFT O" "Change oh-my-zsh theme" "" \
  "" "" "" \
  " Q" "Close active window" "" \
  " SHIFT Q" "Kill process" "" \
  " SHIFT F" "Fullscreen" "" \
  " CTRL F" "Maximize" "" \
  " ALT L" "Toggle layout" "Dwindle | Master" \
  " SPACE" "Toggle float" "single window" \
  " ALT SPACE" "Float all windows" "" \
  " Arrows" "Focus window" "" \
  " SHIFT Arrows" "Resize window" "50 px" \
  " CTRL Arrows" "Move window" "" \
  " ALT Arrows" "Swap window" "" \
  " LMB drag" "Move floating window" "" \
  " RMB drag" "Resize floating window" "" \
  " ALT Scroll" "Desktop zoom in / out" "" \
  "ALT TAB" "Cycle next window" "" \
  "" "" "" \
  " G" "Toggle group" "" \
  " TAB / SHIFT TAB" "Next / prev in group" "" \
  " CTRL TAB" "Change group active" "" \
  " CTRL K" "Move into group left" "" \
  " CTRL L" "Move into group right" "" \
  " CTRL H" "Move out of group" "" \
  "" "" "" \
  " I" "Add master" "Master layout" \
  " CTRL D" "Remove master" "Master layout" \
  " CTRL Return" "Swap with master" "Master layout" \
  " SHIFT I" "Toggle split" "Dwindle layout" \
  " P" "Toggle pseudo" "Dwindle layout" \
  " M" "Set split ratio 0.3" "" \
  "" "" "" \
  " TAB / SHIFT TAB" "Next / prev workspace" "" \
  " 1-0" "Switch to workspace 1-10" "" \
  " SHIFT 1-0" "Move window to workspace" "follows window" \
  " CTRL 1-0" "Move window silently" "stays on current" \
  " SHIFT [ / ]" "Move to prev / next workspace" "" \
  " CTRL [ / ]" "Move silently to prev / next" "" \
  " . / ," "Next / prev workspace" "" \
  " Scroll" "Next / prev workspace" "" \
  " U" "Toggle special workspace" "scratchpad" \
  " SHIFT U" "Send window to special workspace" "" \
  " CTRL F9-F12" "Send workspace to monitor" "l / r / u / d" \
  "" "" "" \
  " ALT O" "Toggle blur" "" \
  " CTRL O" "Toggle window opacity" "active window" \
  " SHIFT A" "Animations menu" "(rofi)" \
  " CTRL R" "Rofi theme selector" "" \
  " CTRL SHIFT R" "Rofi theme selector v2" "" \
  " SHIFT G" "Toggle game mode" "all animations off" \
  " ALT E" "Emoji menu" "(rofi)" \
  "" "" "" \
  " Print" "Screenshot now" "(grim)" \
  " SHIFT Print" "Screenshot area" "(grim + slurp)" \
  " SHIFT S" "Screenshot (swappy)" "annotate" \
  " CTRL Print" "Screenshot in 5s" "(grim)" \
  " CTRL SHIFT Print" "Screenshot in 10s" "(grim)" \
  "ALT Print" "Screenshot active window" "" \
  " F6" "Screenshot now" "laptop key" \
  " SHIFT F6" "Screenshot area" "laptop key" \
  " CTRL F6" "Screenshot in 5s" "laptop key" \
  " ALT F6" "Screenshot in 10s" "laptop key" \
  "ALT F6" "Screenshot active window" "laptop key" \
  "" "" "" \
  "CTRL ALT L" "Session menu" "lock / logout / etc." \
  "CTRL ALT Del" "Exit Hyprland" "immediate" \
  "" "" "" \
  "Volume keys" "Volume down / up / mute" "(noctalia-shell)" \
  "Mic mute key" "Toggle mic mute" "" \
  "Brightness keys" "Brightness down / up" "(noctalia-shell)" \
  "Play / Pause / Next / Prev" "Media controls" "" \
  "Sleep key" "Suspend" "" \
  "Airplane key" "Toggle airplane mode" "" \
  "Touchpad key" "Toggle touchpad" "" \
  "ASUS Fn: Launch1" "ROG control center" "" \
  "ASUS Fn: Launch3" "LED mode cycle" "" \
  "ASUS Fn: Launch4" "Performance profile cycle" "" \
  "" "" ""
