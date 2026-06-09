#!/usr/bin/env bash
# Quick Settings menu — config editor, rainbow borders, and utilities (SUPER SHIFT E)

lua_conf="$HOME/.config/hypr/lua/hyprconf"
term="${TERMINAL:-kitty}"
edit="${EDITOR:-nvim}"

scriptsDir="$HOME/.config/hypr/scripts"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
msg=' ⁉️ Choose what to do ⁉️'
iDIR="$HOME/.config/swaync/images"

show_info() {
    if [[ -f "$iDIR/info.png" ]]; then
        notify-send -i "$iDIR/info.png" "Info" "$1"
    else
        notify-send "Info" "$1"
    fi
}

toggle_rainbow_borders() {
    local rainbow_script="$scriptsDir/display/RainbowBorders.sh"
    local disabled_sh_bak="${rainbow_script}.bak"
    local disabled_bak_sh="$scriptsDir/display/RainbowBorders.bak.sh"
    local refresh_script="$scriptsDir/services/refresh.sh"
    local status=""

    if [[ -f "$disabled_sh_bak" && -f "$disabled_bak_sh" ]]; then
        if [[ "$disabled_sh_bak" -nt "$disabled_bak_sh" ]]; then
            rm -f "$disabled_bak_sh"
        else
            rm -f "$disabled_sh_bak"
        fi
    fi

    if [[ -f "$rainbow_script" ]]; then
        if mv "$rainbow_script" "$disabled_sh_bak"; then
            status="disabled"
            command -v hyprctl &>/dev/null && hyprctl reload >/dev/null 2>&1 || true
        fi
    elif [[ -f "$disabled_sh_bak" ]]; then
        mv "$disabled_sh_bak" "$rainbow_script" && status="enabled"
    elif [[ -f "$disabled_bak_sh" ]]; then
        mv "$disabled_bak_sh" "$rainbow_script" && status="enabled"
    else
        show_info "RainbowBorders script not found in $scriptsDir/display"
        return
    fi

    if [[ -x "$refresh_script" ]]; then
        "$refresh_script" >/dev/null 2>&1 &
    elif [[ "$status" == "enabled" && -x "$rainbow_script" ]]; then
        "$rainbow_script" >/dev/null 2>&1 &
    fi

    [[ -n "$status" ]] && show_info "Rainbow Borders ${status}."
}

rainbow_borders_menu() {
    local rainbow_script="$scriptsDir/display/RainbowBorders.sh"
    local disabled_sh_bak="${rainbow_script}.bak"
    local disabled_bak_sh="$scriptsDir/display/RainbowBorders.bak.sh"
    local refresh_script="$scriptsDir/services/refresh.sh"
    local current="disabled"

    if [[ -f "$rainbow_script" ]]; then
        current=$(grep -E '^EFFECT_TYPE=' "$rainbow_script" 2>/dev/null | sed -E 's/^EFFECT_TYPE="?([^"]*)"?/\1/')
        [[ -z "$current" ]] && current="unknown"
    fi

    local current_display
    case "$current" in
        wallust_random) current_display="Wallust Color" ;;
        rainbow)        current_display="Original Rainbow" ;;
        gradient_flow)  current_display="Gradient Flow" ;;
        *)              current_display="Disabled" ;;
    esac

    local choice
    choice=$(printf "Disable Rainbow Borders\nWallust Color\nOriginal Rainbow\nGradient Flow" \
        | rofi -i -dmenu -config "$rofi_theme" -mesg "Rainbow Borders: current = $current_display")
    [[ -z "$choice" ]] && return

    case "$choice" in
        "Disable Rainbow Borders")
            [[ -f "$rainbow_script" ]] && mv "$rainbow_script" "$disabled_sh_bak"
            current="disabled"
            command -v hyprctl &>/dev/null && hyprctl reload >/dev/null 2>&1 || true
            ;;
        "Wallust Color"|"Original Rainbow"|"Gradient Flow")
            local mode
            case "$choice" in
                "Wallust Color")    mode="wallust_random" ;;
                "Original Rainbow") mode="rainbow" ;;
                "Gradient Flow")    mode="gradient_flow" ;;
            esac
            if [[ ! -f "$rainbow_script" ]]; then
                if   [[ -f "$disabled_sh_bak" ]]; then mv "$disabled_sh_bak" "$rainbow_script"
                elif [[ -f "$disabled_bak_sh" ]]; then mv "$disabled_bak_sh" "$rainbow_script"
                else show_info "RainbowBorders script not found in $scriptsDir/display."; return; fi
            fi
            if grep -q '^EFFECT_TYPE=' "$rainbow_script" 2>/dev/null; then
                sed -i "s/^EFFECT_TYPE=.*/EFFECT_TYPE=\"$mode\"/" "$rainbow_script"
            else
                sed -i "1a EFFECT_TYPE=\"$mode\"" "$rainbow_script"
            fi
            current="$mode"
            ;;
        *) return ;;
    esac

    [[ -x "$refresh_script" ]] && "$refresh_script" >/dev/null 2>&1 &
    [[ "$current" != "disabled" && -x "$rainbow_script" ]] && "$rainbow_script" >/dev/null 2>&1 &
}

menu() {
    cat <<EOF
--- CONFIGURATION ---
Edit Environment & Defaults
Edit Keybinds
Edit Autostart Apps
Edit Window Rules
Edit Appearance
Edit Animations
Edit Input Settings
Edit Laptop Settings
--- UTILITIES ---
Choose Kitty Terminal Theme
Configure Monitors (nwg-displays)
GTK Settings (nwg-look)
QT Apps Settings (qt6ct)
QT Apps Settings (qt5ct)
Choose Hyprland Animations
Choose Monitor Profiles
Choose Rofi Themes
Search for Keybinds
Toggle Game Mode
Switch Dark-Light Theme
Rainbow Borders Mode
--- WAYBAR ---
Waybar Style
Waybar Layout
Toggle Waybar
EOF
}

main() {
    choice=$(menu | rofi -i -dmenu -config "$rofi_theme" -mesg "$msg")

    case "$choice" in
        "Edit Environment & Defaults")  file="$lua_conf/context.lua" ;;
        "Edit Keybinds")                file="$lua_conf/binds.lua" ;;
        "Edit Autostart Apps")          file="$lua_conf/autostart.lua" ;;
        "Edit Window Rules")            file="$lua_conf/rules.lua" ;;
        "Edit Appearance")              file="$lua_conf/options.lua" ;;
        "Edit Animations")              file="$lua_conf/animations.lua" ;;
        "Edit Input Settings")          file="$lua_conf/options.lua" ;;
        "Edit Laptop Settings")         file="$lua_conf/context.lua" ;;
        "Choose Kitty Terminal Theme")  "$scriptsDir/display/kitty-themes.sh" ;;
        "Configure Monitors (nwg-displays)")
            command -v nwg-displays &>/dev/null || { notify-send "Error" "Install nwg-displays first"; exit 1; }
            nwg-displays ;;
        "GTK Settings (nwg-look)")
            command -v nwg-look &>/dev/null || { notify-send "Error" "Install nwg-look first"; exit 1; }
            nwg-look ;;
        "QT Apps Settings (qt6ct)")
            command -v qt6ct &>/dev/null || { notify-send "Error" "Install qt6ct first"; exit 1; }
            qt6ct ;;
        "QT Apps Settings (qt5ct)")
            command -v qt5ct &>/dev/null || { notify-send "Error" "Install qt5ct first"; exit 1; }
            qt5ct ;;
        "Choose Hyprland Animations")   "$scriptsDir/display/animations.sh" ;;
        "Choose Monitor Profiles")      "$scriptsDir/display/monitor-profiles.sh" ;;
        "Choose Rofi Themes")           "$scriptsDir/rofi/rofi-theme-selector.sh" ;;
        "Search for Keybinds")          "$scriptsDir/input/keybinds.sh" ;;
        "Toggle Game Mode")             "$scriptsDir/session/game-mode.sh" ;;
        "Switch Dark-Light Theme")      "$scriptsDir/display/dark-light.sh" ;;
        "Rainbow Borders Mode")         rainbow_borders_menu ;;
        "Waybar Style")                 "$scriptsDir/display/waybar-style.sh" ;;
        "Waybar Layout")                "$scriptsDir/display/waybar-layout.sh" ;;
        "Toggle Waybar")
            if pgrep -x waybar >/dev/null; then
                pgrep -x waybar | xargs -r kill
            else
                waybar &
            fi
            ;;
        *) return ;;
    esac

    [[ -n "$file" ]] && $term -e $edit "$file"
}

pkill rofi 2>/dev/null || true

main
