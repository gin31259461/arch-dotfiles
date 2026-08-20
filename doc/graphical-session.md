# Graphical Session Ownership

This document explains the non-trivial startup relationships for the Hyprland
desktop. It intentionally does not duplicate the complete service inventory;
`.local/libexec/homebase/setup/desktop-session.sh` is authoritative for which
units Homebase reconciles.

## Startup Owners

UWSM starts Hyprland from `.zprofile` and exposes
`graphical-session.target`. Each application must have one startup owner:

| Owner | Responsibility |
| --- | --- |
| Package user unit | Services maintained by an installed package |
| Tracked user unit | Custom desktop and tray behavior owned by dotfiles |
| System XDG autostart | System-provided applets and input method |
| Hyprland autostart | Compositor-local runtime effects only |

Do not copy package-provided units into this repository. Do not add a second
XDG or Hyprland startup path for an application already owned by a user unit.
Generated `graphical-session.target.wants/` links are machine state and remain
untracked.

The dotfiles-owned setup script reloads the user manager and repairs enablement
for its configured inventory. Package-provided units that must join an already
active graphical target may be started immediately; tracked custom units are
enable-only and normally join the next graphical session.

## Credential and Desktop Shell Flow

KeePassXC owns database unlock and FreeDesktop Secret Service readiness.
Noctalia starts after that readiness boundary so secret-backed storage does not
race the database unlock. After Noctalia exposes its StatusNotifierWatcher, the
tray-refresh helper restarts KeePassXC once to repair tray registration. That
helper does not participate in database unlock.

Keep these responsibilities separate:

1. KeePassXC opens and unlocks the database.
2. KeePassXC exposes the required Secret Service collection.
3. Noctalia starts after Secret Service is ready.
4. The one-shot helper repairs only KeePassXC tray registration.

Noctalia uses the default Secret Service storage key. Its clipboard history is
disabled because Vicinae owns clipboard history.

## Machine-Local Security State

The following are machine-local and must not be tracked or printed:

- the KeePassXC database;
- its encrypted systemd credential;
- `.config/keepassxc/keepassxc.ini`; and
- the retired Noctalia storage key retained for recovery.

The KeePassXC INI can contain KeeShare private key material. Inspect only the
specific keys required for a task. Unattended Secret Service startup requires
access policy that does not wait for a per-item confirmation prompt; limit the
exposed database group to the desktop clients that need it.

## Other Ownership Decisions

- Vicinae owns launching, clipboard history, window switching, file search,
  emoji selection, and dmenu behavior. Do not restore Rofi or related theme
  generation.
- Remmina's hidden XDG desktop marker prevents a second autostart path while
  its tracked user unit owns the tray process.
- NetworkManager, Blueman, and fcitx5 remain under system XDG autostart.
- Hyprland autostart is reserved for compositor-local effects.

## Changing the Flow

When adding or removing a session application:

1. Choose exactly one startup owner.
2. Add or update custom unit source files when dotfiles own the behavior.
3. Update `desktop-session.sh` when its reconciliation inventory changes.
4. Keep credential readiness and tray repair ordering intact.
5. Update this document only when the ownership model or interaction changes,
   not for routine inventory changes.
6. Run the setup fake-command harness and systemd unit verification.

Read-only validation:

```bash
bash ~/.local/libexec/homebase/setup/test.sh
systemd-analyze --user verify ~/.config/systemd/user/*.service
systemctl --user --failed
```

Do not run `hb setup --hook desktop-session` solely for validation; it reloads
the user manager and can enable or start services.
