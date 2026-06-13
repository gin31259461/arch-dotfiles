# Apps Note

## Zsh

Uses **Oh My Zsh** and **Powerlevel10k**.

`~/.local/bin/bootstrap.sh` installs Oh My Zsh, `zsh-autosuggestions`,
`zsh-syntax-highlighting`, and Powerlevel10k when accepted during bootstrap.
The active theme and plugins are tracked in `~/.zshrc`.

Run the interactive prompt configurator only when changing the prompt style:

```bash
p10k configure
```

## Clipboard Manager

Uses [`cliphist`][cliphist].

Install the `capture` package group with `~/.local/bin/install-packages.sh`.
Autostart and keybind behavior is tracked in the Hyprland config under
`~/.config/hypr/lua/hyprconf/`.

## Fcitx5

Install the `input` package group with `~/.local/bin/install-packages.sh`.
Fcitx5 autostart and environment variables are tracked in the Hyprland config
under `~/.config/hypr/lua/hyprconf/`.

Some Electron apps require explicit Wayland IME flags. Shared Electron flags
are tracked in `~/.config/electron-flags.conf`; add app-specific flag files
only when an app still needs one.

[cliphist]: https://wiki.hyprland.org/Useful-Utilities/Clipboard-Managers/
