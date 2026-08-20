#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
fake_bin="$temporary/bin"
root="$temporary/root"
test_home="$temporary/home"
log="$temporary/commands.log"
mkdir -p "$fake_bin" "$root/etc" "$test_home"

for script in "$script_dir"/*.sh; do
  bash -n "$script"
done

cat >"$fake_bin/lsmod" <<'EOF'
#!/usr/bin/env bash
printf 'Module Size Used by\namdgpu 1 0\n'
EOF
cat >"$fake_bin/hb" <<'EOF'
#!/usr/bin/env bash
printf '#compdef hb\n'
EOF
cat >"$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
destination="${!#}"
printf 'git %s\n' "$*" >>"$HOMEBASE_SETUP_TEST_LOG"
mkdir -p "$destination/.git"
EOF
cat >"$fake_bin/groups" <<'EOF'
#!/usr/bin/env bash
printf '%s wheel\n' "$1"
EOF
cat >"$fake_bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >>"$HOMEBASE_SETUP_TEST_LOG"
EOF
cat >"$fake_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf 'systemctl %s\n' "$*" >>"$HOMEBASE_SETUP_TEST_LOG"
case "$*" in
  '--user is-active --quiet graphical-session.target') exit 1 ;;
  '--user cat '*) exit 0 ;;
  '--user is-active --quiet '*) exit 0 ;;
esac
EOF
chmod +x "$fake_bin"/*

export HOMEBASE_SETUP_ROOT="$root"
export HOMEBASE_SETUP_TEST_LOG="$log"
export PATH="$fake_bin:$PATH"
export HOME="$test_home"
export USER=tester

printf 'MODULES=()\nHOOKS=(base udev)\n' >"$root/etc/mkinitcpio.conf"
bash "$script_dir/system.sh"
grep -Fxq 'MODULES=(usbhid xhci_pci amdgpu)' "$root/etc/mkinitcpio.conf"

bash "$script_dir/shell.sh"
grep -Fxq '#compdef hb' "$root/usr/share/zsh/site-functions/_hb"
grep -Fxq \
  'git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git '"$test_home/.oh-my-zsh" \
  "$log"
grep -Fxq \
  'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '"$test_home/.oh-my-zsh/custom/themes/powerlevel10k" \
  "$log"
clone_count="$(grep -c '^git clone ' "$log")"
bash "$script_dir/shell.sh"
if [[ "$(grep -c '^git clone ' "$log")" -ne "$clone_count" ]]; then
  printf 'shell setup cloned an existing repository twice\n' >&2
  exit 1
fi

bash "$script_dir/autologin.sh"
grep -Fq -- '--autologin tester' "$root/etc/systemd/system/getty@tty1.service.d/override.conf"

bash "$script_dir/docker.sh"
grep -Fxq 'sudo systemctl enable --now docker.service' "$log"
grep -Fxq 'sudo gpasswd -a tester docker' "$log"

bash "$script_dir/desktop-session.sh"
grep -Fxq 'systemctl --user enable hyprpolkitagent.service' "$log"
grep -Fxq 'systemctl --user enable vesktop.service' "$log"

printf 'setup script tests passed\n'
