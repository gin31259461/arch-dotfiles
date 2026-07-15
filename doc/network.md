# Network

## Allow LAN access when using tailscale exit node

for example:

```bash
tailscale up --exit-node=nixos-dev --exit-node-allow-lan-access --login-server=https://vpn.wke.csie.ncnu.edu.tw
```

## Setup hotspot

after install homebase pkg with group `network`

```bash
nmcli conn modify Arch-Hyprland connection.interface-name __ip link__
nmcli conn modify Arch-Hyprland 802-11-wireless-security.psk __new passwd__
```
