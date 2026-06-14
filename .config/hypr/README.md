# Hyprland Config

Personal Hyprland configuration for Hyprland 0.55+ using Lua.

## Structure

```text
~/.config/hypr/
├── hyprland.lua              # Minimal Lua entrypoint
├── lua/hyprconf/             # Hyprland Lua modules
│   ├── init.lua              # Module load order
│   ├── context.lua           # Paths, defaults, devices
│   ├── env.lua               # Environment variables
│   ├── autostart.lua         # Startup commands
│   ├── profile.lua           # Shared user profile loader
│   ├── monitors.lua          # Active/fallback monitor profile loader
│   ├── options.lua           # General/input/layout/misc options
│   ├── animations.lua        # Active/fallback animation profile loader
│   ├── gestures.lua          # Touchpad gestures
│   ├── binds.lua             # Keybinds
│   ├── rules.lua             # Window and layer rules
│   ├── colors.lua            # Noctalia color loader
│   ├── color.lua             # Hex color helpers and palette generation
│   └── util.lua              # Shared Lua helpers
├── lua/user/                 # Active user profile snippets
│   ├── monitors.lua          # Active monitor profile
│   └── animations.lua        # Active animation profile
├── profiles/                 # Profile presets and selected-profile memory
│   ├── monitor/
│   └── animation/
├── effects/                  # Generated color/effect state
├── scripts/                  # Helper scripts and menus
├── hyprlock.conf
├── hypridle.conf
└── initial-boot.sh
```

## Editing

- Defaults, paths, and device names: `lua/hyprconf/context.lua`
- Noctalia shell integration: `lua/hyprconf/context.lua` (`noctalia_shell`)
- Keybinds: `lua/hyprconf/binds.lua`
- Autostart: `lua/hyprconf/autostart.lua`
- Appearance/input/layout/misc: `lua/hyprconf/options.lua`
- Window and layer rules: `lua/hyprconf/rules.lua`
- Active profiles: `lua/user/`
- Profile presets: `profiles/`
- Profile selector: `scripts/profile-selector/select.sh`
- Noctalia theme generation: `lua/hyprconf/theme/noctalia.lua` writes quickshell, rofi, Hyprland, and `effects/colors-hyprland.conf`

Run validation with:

```sh
hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

## References

this config if based on the work of [Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr)
