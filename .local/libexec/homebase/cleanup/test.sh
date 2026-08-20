#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
fake_bin="$temporary/bin"
log="$temporary/commands.log"
cache="$temporary/cache"
mkdir -p "$fake_bin" "$cache/_cacache" "$temporary/yay/subdir"
printf 'payload' >"$cache/_cacache/data"
printf 'build' >"$temporary/yay/subdir/data"

for script in "$script_dir"/*.sh; do
  bash -n "$script"
done

cat >"$fake_bin/pacman" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "-Qdtq" ]]; then
  printf 'old-lib\nunused-tool\n'
  exit 0
fi
printf 'pacman %s\n' "$*" >>"$HOMEBASE_CLEANUP_TEST_LOG"
EOF
cat >"$fake_bin/journalctl" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "--disk-usage" ]]; then
  printf 'Archived and active journals take up 150.0M in the file system.\n'
  exit 0
fi
printf 'journalctl %s\n' "$*" >>"$HOMEBASE_CLEANUP_TEST_LOG"
EOF
cat >"$fake_bin/npm" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "config get cache" ]]; then
  printf '%s\n' "$HOMEBASE_CLEANUP_TEST_CACHE"
  exit 0
fi
printf 'npm %s\n' "$*" >>"$HOMEBASE_CLEANUP_TEST_LOG"
EOF
cat >"$fake_bin/paccache" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "-dq" ]]; then
  exit 0
fi
printf 'paccache %s\n' "$*" >>"$HOMEBASE_CLEANUP_TEST_LOG"
EOF
cat >"$fake_bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >>"$HOMEBASE_CLEANUP_TEST_LOG"
EOF
chmod +x "$fake_bin"/*

export HOMEBASE_CLEANUP_TEST_CACHE="$cache"
export HOMEBASE_CLEANUP_TEST_LOG="$log"
export PATH="$fake_bin:$PATH"

directory_scan="$(bash "$script_dir/directory.sh" scan "$temporary/yay" "AUR build cache")"
grep -Eq '^(partial|bad)[[:space:]]' <<<"$directory_scan"
grep -Fq "Path: $temporary/yay" <<<"$directory_scan"

orphan_scan="$(bash "$script_dir/orphans.sh" scan)"
grep -Fq $'bad\t2 orphaned package(s)' <<<"$orphan_scan"
grep -Fq 'old-lib' <<<"$orphan_scan"

journal_scan="$(bash "$script_dir/journal.sh" scan)"
grep -Fq $'bad\t50.0 MiB over 100.0 MiB target' <<<"$journal_scan"

npm_scan="$(bash "$script_dir/npm-cache.sh" scan)"
grep -Fq 'npm content-addressable cache' <<<"$npm_scan"

bash "$script_dir/directory.sh" run "$temporary/yay" "AUR build cache"
[[ ! -e "$temporary/yay" ]]
bash "$script_dir/orphans.sh" run
bash "$script_dir/journal.sh" run
bash "$script_dir/pacman-cache.sh" run
bash "$script_dir/npm-cache.sh" run

grep -Fxq 'sudo pacman -Rns old-lib unused-tool' "$log"
grep -Fxq 'sudo journalctl --vacuum-size=100M' "$log"
grep -Fxq 'sudo paccache -r' "$log"
grep -Fxq 'npm cache clean --force' "$log"

printf 'cleanup script tests passed\n'
