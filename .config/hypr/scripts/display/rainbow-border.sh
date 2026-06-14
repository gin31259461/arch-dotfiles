#!/usr/bin/env bash
# Possible values: "material_random", "rainbow", "gradient_flow"
EFFECT_TYPE="gradient_flow"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

MODE_FILE="$RAINBOW_BORDER_MODE_FILE"
MATERIAL_COLORS_SOURCE="$EFFECTS_DIR/colors-hyprland.conf"

EFFECT_TYPE="$(rainbow_border_mode)"

if [[ "$EFFECT_TYPE" == "disabled" ]]; then
  exit 0
fi

MATERIAL_COLORS=()

load_material_colors() {
  local line value

  [[ -f "$MATERIAL_COLORS_SOURCE" ]] || return 0

  while IFS= read -r line; do
    case "$line" in
    '$color'*)
      if [[ "$line" =~ 0x([0-9A-Fa-f]{8}) ]]; then
        MATERIAL_COLORS+=("0x${BASH_REMATCH[1]}")
      elif [[ "$line" =~ \#([0-9A-Fa-f]{6}) ]]; then
        MATERIAL_COLORS+=("0xff${BASH_REMATCH[1]}")
      elif [[ "$line" =~ rgb\(([0-9A-Fa-f]{6})\) ]]; then
        MATERIAL_COLORS+=("0xff${BASH_REMATCH[1]}")
      elif [[ "$line" =~ rgb\(([0-9]+),[[:space:]]*([0-9]+),[[:space:]]*([0-9]+)\) ]]; then
        printf -v value '0xff%02x%02x%02x' \
          "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
        MATERIAL_COLORS+=("$value")
      fi
      ;;
    esac
  done <"$MATERIAL_COLORS_SOURCE"
}

# ---------- LOAD MATERIAL COLORS ----------
if [[ "$EFFECT_TYPE" == "material_random" || "$EFFECT_TYPE" == "gradient_flow" ]]; then
  load_material_colors

  if ((${#MATERIAL_COLORS[@]} == 0)); then
    EFFECT_TYPE="rainbow"
  fi
fi

# ---------- RANDOM MATERIAL COLORS ----------
material_random() {
  echo "${MATERIAL_COLORS[RANDOM % ${#MATERIAL_COLORS[@]}]}"
}

# ---------- RAINBOW COLORS ----------
random_hex() {
  echo "0xff$(openssl rand -hex 3)"
}

# ---------- FLOW MODE ----------
BASE_COLOR="${MATERIAL_COLORS[10]}"
GRAD1_COLOR="${MATERIAL_COLORS[14]}"
GRAD2_COLOR="${MATERIAL_COLORS[13]}"
GLOW_COLOR="${MATERIAL_COLORS[15]}"

MAX_POS=10
GLOW_POS=0

gradient_flow_color() {
  local pos=$1
  local d=$((pos - GLOW_POS))

  if ((d > MAX_POS / 2)); then d=$((d - MAX_POS)); fi
  if ((d < -MAX_POS / 2)); then d=$((d + MAX_POS)); fi

  case "${d#-}" in
  0) echo "$GLOW_COLOR" ;;
  1) echo "$GRAD1_COLOR" ;;
  2) echo "$GRAD2_COLOR" ;;
  *) echo "$BASE_COLOR" ;;
  esac

  if ((pos == MAX_POS - 1)); then
    GLOW_POS=$(((GLOW_POS + 1) % MAX_POS))
  fi
}

# ---------- Main function ----------

get_color() {
  if [[ "$EFFECT_TYPE" == "material_random" && ${#MATERIAL_COLORS[@]} -gt 0 ]]; then
    material_random
  elif [[ "$EFFECT_TYPE" == "gradient_flow" && ${#MATERIAL_COLORS[@]} -ge 16 ]]; then
    gradient_flow_color "$1"
  else
    random_hex
  fi
}

active_border=(
  "$(get_color 0)" "$(get_color 1)" "$(get_color 2)" "$(get_color 3)" "$(get_color 4)"
  "$(get_color 5)" "$(get_color 6)" "$(get_color 7)" "$(get_color 8)" "$(get_color 9)"
)

lua_colors=""
for color in "${active_border[@]}"; do
  lua_colors="${lua_colors}\"${color}\", "
done

hypr_set_config "{ general = { col = { active_border = { colors = { ${lua_colors} }, angle = 270 } } } }"
