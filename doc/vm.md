# VMware

Notes for running Arch Linux and Hyprland as a VMware guest.

## Known Issues

- **Qt and GTK3 apps** may fail to launch under Hyprland in a VM.
  Electron-based apps generally work.
- **`xdg-desktop-portal-hyprland`** may not function correctly in a VM. Try
  [`xdg-desktop-portal-wlr`][xdpw] as an alternative.
- Enable the VMware option to **pass battery information to guest** so the
  system tray shows correct battery status.

## Enable Extra Mouse Buttons

With the VM powered off, add this to the `.vmx` file:

```vmx
usb.generic.allowHID = "TRUE"
mouse.vusb.enable = "TRUE"
```

## Fix Audio Stuttering

Add this VMware setting to the `.vmx` file while the VM is powered off:

```vmx
sound.highPriority = "TRUE"
```

Create the WirePlumber ALSA tuning directory:

```bash
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
```

Create `~/.config/wireplumber/wireplumber.conf.d/50-alsa-config.conf`:

```conf
monitor.alsa.rules = [
  {
    matches = [{ node.name = "~alsa_output.*" }]
    actions = {
      update-props = {
        api.alsa.period-size = 1024
        api.alsa.headroom    = 8192
      }
    }
  }
]
```

Further reading:

- [Audio and video stuttering in VMs][arch-forum-stutter]
- [PipeWire documentation][pipewire-docs]

[arch-forum-stutter]: https://bbs.archlinux.org/viewtopic.php?id=280654
[pipewire-docs]: https://wiki.archlinux.org/title/PipeWire
[xdpw]: https://archlinux.org/packages/?name=xdg-desktop-portal-wlr
