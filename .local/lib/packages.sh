#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  packages.sh  ·  Package group loader for install-packages.sh
#
#  Package groups live in TOML files under:
#    ~/.local/lib/packages.d/*.toml
#
#  Each named table is one package group:
#    [stable-key]
#    label     = "Display Label"
#    official  = ["pacman-package"]
#    aur       = ["aur-package"]
#
#  This file intentionally exposes the legacy PKG_GROUPS array so the installer
#  can keep using its existing selection and install logic.
# ─────────────────────────────────────────────────────────────────────────────

declare -a PKG_GROUPS=()

_packages_dir="${PACKAGES_DIR:-$HOME/.local/lib/packages.d}"
_packages_loader="${PACKAGES_LOADER:-$HOME/.local/lib/read-packages-toml.py}"

if ! command -v python3 &>/dev/null; then
  printf 'ERROR: python3 is required to read package TOML files\n' >&2
  return 1 2>/dev/null || exit 1
fi

if [[ ! -d "$_packages_dir" ]]; then
  printf 'ERROR: package directory not found: %s\n' "$_packages_dir" >&2
  return 1 2>/dev/null || exit 1
fi

if [[ ! -f "$_packages_loader" ]]; then
  printf 'ERROR: package TOML loader not found: %s\n' "$_packages_loader" >&2
  return 1 2>/dev/null || exit 1
fi

if ! _package_records="$(python3 "$_packages_loader" "$_packages_dir")"; then
  return 1 2>/dev/null || exit 1
fi

while IFS='|' read -r key label official aur; do
  [[ -n "$key" ]] || continue
  PKG_GROUPS+=("$key|$label|$official|$aur")
done <<<"$_package_records"

unset _packages_dir _packages_loader _package_records
