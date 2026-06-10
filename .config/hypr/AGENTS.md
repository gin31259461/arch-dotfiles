# AGENTS.md

Guidance for coding agents working in this Hyprland config repository.

## Scope

- This repo is a personal Hyprland 0.55+ configuration using Lua as the main entrypoint.
- Keep changes practical, local, and consistent with existing Lua modules and shell helpers.
- Do not revert user changes or generated local state unless explicitly requested.

## Layout

- `hyprland.lua` is the minimal Lua entrypoint.
- `lua/hyprconf/` contains tracked Hyprland modules.
- `lua/user/` contains active user-local Lua profile data.
- `profiles/<category>/*.lua` contains reusable profile presets.
- `profiles/.selected/<category>` remembers the selected preset per category.
- `scripts/lib/` contains shared shell helpers:
  - `common.sh` for paths, process helpers, and reload helpers.
  - `notify.sh` for notifications.
  - `rofi.sh` for rofi menu helpers.
- `scripts/profile-selector/select.sh` copies presets into the matching `lua/user` target.

## Editing Rules

- Prefer extending existing modules over adding new top-level concepts.
- Keep Lua modules returning an `M` table with `M.setup()` when they are loaded by `lua/hyprconf/init.lua`.
- Keep monitor profiles as plain Lua snippets that call `hl.monitor(...)`.
- Keep animation profiles as Lua snippets that call `profile.apply_animation(...)`.
- For shell scripts, source shared helpers instead of duplicating paths, `notify-send`, rofi cleanup, or process-kill logic.
- Use `#!/usr/bin/env bash`, `set -euo pipefail` for new non-trivial shell scripts, and quote variables.
- Preserve generated or machine-written files unless the task is specifically about regeneration.

## Style

- Follow `.editorconfig`.
- Shell: 2-space indent, Bash syntax, formatted with `shfmt`.
- Lua: 2-space indent.
- Keep comments useful and short; avoid narrating obvious assignments.
- Prefer ASCII unless the edited file already uses non-ASCII for UI text or symbols.

## Validation

Run the relevant checks before finishing:

```sh
find scripts -type f -name '*.sh' ! -path 'scripts/rofi/rofi-emoji.sh' -print0 | xargs -0 shfmt -d
while IFS= read -r -d '' f; do bash -n "$f" || exit 1; done < <(find scripts -type f -name '*.sh' ! -path 'scripts/rofi/rofi-emoji.sh' -print0)
bash -n initial-boot.sh
find lua profiles -type f -name '*.lua' -print0 | xargs -0 luac -p
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

`scripts/rofi/rofi-emoji.sh` is excluded from shell parsing/formatting because it embeds emoji list data and is not valid standalone Bash.

## Safety

- Avoid destructive commands such as `git reset --hard`, `git checkout --`, or deleting config state.
- If a script launches UI tools such as rofi or sends desktop notifications, prefer syntax/static checks unless runtime behavior is explicitly requested.
- Be careful with scripts that affect monitors, themes, wallpaper, audio, or running processes; validate code paths before triggering them.
