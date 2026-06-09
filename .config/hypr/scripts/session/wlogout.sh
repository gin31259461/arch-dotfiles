#!/usr/bin/env bash
# Provides logout and power management menu

# Check if wlogout is already running
if pgrep -x "wlogout" >/dev/null; then
  pkill -x "wlogout"
  exit 0
fi

# Detect monitor resolution and scaling factor
resolution=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .height / .scale' | awk -F'.' '{print $1}')
hypr_scale=$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .scale')

# Map resolution thresholds to margin bases and button counts
declare -A margins=([2160]=600 [1600]=400 [1440]=400 [1080]=200 [720]=50)
declare -A buttons=([2160]=6 [1600]=6 [1440]=6 [1080]=6 [720]=3)
base=0
btn=6
for threshold in 2160 1600 1440 1080 720; do
  if ((resolution >= threshold)); then
    base=${margins[$threshold]}
    btn=${buttons[$threshold]}
    break
  fi
done

if ((base > 0)); then
  T_val=$(awk "BEGIN {printf \"%.0f\", $base * $threshold * $hypr_scale / $resolution}")
  B_val=$T_val
  wlogout --protocol layer-shell -b "$btn" -T "$T_val" -B "$B_val" &
else
  wlogout &
fi
