#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

hb completion zsh | setup_install_root_file /usr/share/zsh/site-functions/_hb
printf 'Installed Zsh completion for hb\n'
