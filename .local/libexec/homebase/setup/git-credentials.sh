#!/usr/bin/env bash

set -euo pipefail

password_store="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
if [[ ! -s "$password_store/.gpg-id" ]]; then
  before="$(mktemp)"
  after="$(mktemp)"
  added="$(mktemp)"
  trap 'rm -f "$before" "$after" "$added"' EXIT

  gpg --batch --with-colons --fingerprint --list-secret-keys |
    awk -F: '$1 == "sec" {want=1} $1 == "ssb" {want=0} $1 == "fpr" && want {print $10; want=0}' |
    sort -u >"$before"
  printf 'GPG will prompt for your identity and key passphrase\n'
  gpg --gen-key
  gpg --batch --with-colons --fingerprint --list-secret-keys |
    awk -F: '$1 == "sec" {want=1} $1 == "ssb" {want=0} $1 == "fpr" && want {print $10; want=0}' |
    sort -u >"$after"
  comm -13 "$before" "$after" >"$added"
  if [[ "$(wc -l <"$added")" -ne 1 ]]; then
    printf 'Expected exactly one newly generated primary GPG key\n' >&2
    exit 1
  fi
  pass init "$(<"$added")"
fi

git-credential-manager configure
git config --global credential.credentialStore gpg
