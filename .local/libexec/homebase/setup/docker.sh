#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

sudo systemctl enable --now docker.service
setup_add_user_to_group "${USER:?USER is required}" docker
