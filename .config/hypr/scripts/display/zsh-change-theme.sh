#!/usr/bin/env bash
# Changes Zsh theme dynamically

# preview of theme can be view here: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# after choosing theme, TTY need to be closed and re-open

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../lib/notify.sh
source "$SCRIPT_DIR/lib/notify.sh"
# shellcheck source=../lib/rofi.sh
source "$SCRIPT_DIR/lib/rofi.sh"

rofi_theme="$ROFI_CONFIG_DIR/config-zsh-theme.rasi"

themes_dir="$HOME/.oh-my-zsh/themes"
file_extension=".zsh-theme"

mapfile -t themes_array < <(find -L "$themes_dir" -type f -name "*${file_extension}" -printf "%f\n" | sed "s/${file_extension}//")
themes_array=("Random" "${themes_array[@]}")

main() {
  choice=$(printf '%s\n' "${themes_array[@]}" | rofi_dmenu "$rofi_theme" "")
  [[ -z "$choice" ]] && exit 0

  zsh_path="$HOME/.zshrc"

  if [[ "$choice" == "Random" ]]; then
    themes_only=("${themes_array[@]:1}")
    random_theme="${themes_only[$((RANDOM % ${#themes_only[@]}))]}"
    theme_to_set="$random_theme"
    notify_info "Zsh Theme" "Random: $random_theme" "$NOTIFY_FALLBACK_ICON" "zsh-theme"
  else
    theme_to_set="$choice"
    notify_info "Zsh Theme" "Selected: $choice" "$NOTIFY_FALLBACK_ICON" "zsh-theme"
  fi

  if [[ -f "$zsh_path" ]]; then
    safe_theme=$(printf '%s' "$theme_to_set" | sed 's/[\/&]/\\&/g')
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"${safe_theme}\"/" "$zsh_path"
    notify_success "OMZ Theme" "Applied. Restart your terminal." "$NOTIFY_FALLBACK_ICON" "zsh-theme"
  else
    notify_error "OMZ Theme" "~/.zshrc file not found." "" "zsh-theme"
  fi
}

rofi_close_existing

main
