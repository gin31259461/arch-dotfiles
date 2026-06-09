#!/usr/bin/env bash
# Reports battery status and capacity for all detected batteries

for i in {0..3}; do
  if [[ -f "/sys/class/power_supply/BAT${i}/capacity" ]]; then
    battery_status=$(<"/sys/class/power_supply/BAT${i}/status")
    battery_capacity=$(<"/sys/class/power_supply/BAT${i}/capacity")
    echo "Battery: ${battery_capacity}% (${battery_status})"
  fi
done
