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
│   ├── monitors.lua          # monitors.conf loader
│   ├── options.lua           # General/input/layout/misc options
│   ├── animations.lua        # Curves and animations
│   ├── gestures.lua          # Touchpad gestures
│   ├── binds.lua             # Keybinds
│   ├── rules.lua             # Window and layer rules
│   ├── colors.lua            # Wallust/Noctalia color loader
│   └── util.lua              # Shared Lua helpers
├── monitors.conf             # Dynamic monitor profile data
├── wallust/                  # Generated color data
├── scripts/                  # Helper scripts and menus
├── monitor-profiles/         # Monitor profile presets
├── hyprlock.conf
├── hyprlock-2k.conf
├── hyprlock-1080.conf
├── hypridle.conf
└── initial-boot.sh
```

## Editing

- Defaults, paths, and device names: `lua/hyprconf/context.lua`
- Keybinds: `lua/hyprconf/binds.lua`
- Autostart: `lua/hyprconf/autostart.lua`
- Appearance/input/layout/misc: `lua/hyprconf/options.lua`
- Window and layer rules: `lua/hyprconf/rules.lua`
- Animations: `lua/hyprconf/animations.lua`
- Noctalia theme generation: `lua/hyprconf/theme/noctalia.lua`

Run validation with:

```sh
Hyprland --verify-config --config ~/.config/hypr/hyprland.lua
```

## Notes

`monitors.conf` is intentionally still data-oriented so tools such as `nwg-displays` and monitor profile scripts can update it. Generated color files under `wallust/` and `noctalia/` are also kept as data inputs; the Lua config reads them at startup.

## References

- [Hyprland-Dots](https://github.com/LinuxBeginnings/Hyprland-Dots/tree/main/config/hypr)
