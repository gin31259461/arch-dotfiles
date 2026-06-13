# System Maintenance

## System Cleaning

Use the interactive cleanup script for a guided experience:

```bash
~/.local/bin/cleanup.sh
```

It presents a fzf multi-select menu with current disk usage per task. If fzf is
not available, it falls back to a numbered list. It confirms before making any
changes.

Cleanup task labels and descriptions are defined in
`~/.local/lib/cleanup.toml`. The actual runners live in
`~/.local/bin/cleanup.sh`.

Run non-interactively, skipping confirmations, with `--yes`:

```bash
~/.local/bin/cleanup.sh --yes
```

## Known Upgrade Issues

| Error | Fix |
| ----- | --- |
| Unknown trust signature | Refresh the Arch Linux keyring. |
| `linux-firmware >= 20250613.12fe085f-5` fails | Follow manual intervention. |

References:

- [Pacman package signing][pacman-signing]
- [Arch Linux news][arch-news]

## Notes

- **Electron apps, such as Discord and VS Code**, cannot share screens under
  Hyprland by default. Use a Wayland-aware screen share portal or check
  app-specific flags.

[arch-news]: https://archlinux.org/news/
[pacman-signing]: https://wiki.archlinux.org/title/Pacman/Package_signing
