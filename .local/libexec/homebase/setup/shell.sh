#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

clone_if_missing() {
  local url="$1"
  local destination="$2"
  if [[ -d "$destination/.git" ]]; then
    return
  fi
  git clone --depth=1 "$url" "$destination"
}

oh_my_zsh="$HOME/.oh-my-zsh"
custom="$oh_my_zsh/custom"

clone_if_missing https://github.com/ohmyzsh/ohmyzsh.git "$oh_my_zsh"
clone_if_missing \
  https://github.com/zsh-users/zsh-autosuggestions \
  "$custom/plugins/zsh-autosuggestions"
clone_if_missing \
  https://github.com/zsh-users/zsh-syntax-highlighting \
  "$custom/plugins/zsh-syntax-highlighting"
clone_if_missing \
  https://github.com/romkatv/powerlevel10k.git \
  "$custom/themes/powerlevel10k"

hb completion zsh | setup_install_root_file /usr/share/zsh/site-functions/_hb
printf 'Shell framework, plugins, theme, and hb completion are ready\n'
