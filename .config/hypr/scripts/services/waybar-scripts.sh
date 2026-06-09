#!/usr/bin/env bash
# Waybar click-handler helper — launches terminal apps from waybar modules
# Usage: waybar-scripts.sh [--btop|--nvtop|--nmtui|--term|--files]

term="${TERMINAL:-kitty}"
files="${FILE_MANAGER:-thunar}"

case "$1" in
    --btop)   exec $term --title btop  -e btop ;;
    --nvtop)  exec $term --title nvtop -e nvtop ;;
    --nmtui)  exec $term -e nmtui ;;
    --term)   exec $term ;;
    --files)
        if [[ -z "$files" ]]; then
            notify-send -u low "waybar-scripts" "FILE_MANAGER is empty"
            exit 1
        fi
        exec $files
        ;;
    *)
        echo "Usage: $0 [--btop | --nvtop | --nmtui | --term | --files]"
        exit 1
        ;;
esac
