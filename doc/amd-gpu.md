# AMD GPU Setup

Post-install checklist for AMD GPU users on Arch Linux and Hyprland.
It covers driver verification, Vulkan, hardware video acceleration,
Hyprland environment variables, and performance monitoring.

## Kernel Driver and Firmware

Verify that the kernel is using the `amdgpu` driver:

```bash
lspci -k | grep -A 3 -E "(VGA|3D)"
```

Expected output:

```text
Kernel driver in use: amdgpu
```

For older GCN 1.0 or 2.0 cards, the `radeon` driver may be preferred by
default. Force `amdgpu` by adding the matching parameter to your kernel command
line:

- GCN 1.0, Southern Islands:
  `radeon.si_support=0 amdgpu.si_support=1`
- GCN 2.0, Sea Islands:
  `radeon.cik_support=0 amdgpu.cik_support=1`

Verify that the module is loaded:

```bash
lsmod | grep amdgpu
```

Make sure the `linux-firmware` package is installed. It provides the GPU
firmware blobs required by `amdgpu`.

## User-Space Drivers and Vulkan

Install Mesa, 32-bit libraries for Steam and Proton, and Vulkan tools:

```bash
sudo pacman -S mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon \
  vulkan-tools
```

Verify Vulkan support:

```bash
vulkaninfo | grep "deviceName"
```

Expected output is your AMD GPU model name. If the output shows `llvmpipe`, the
software fallback is active. Check that `vulkan-radeon` is installed and that
the correct driver is in use.

## Hardware Video Acceleration

VA-API offloads video decoding to the GPU, which reduces CPU load and improves
power efficiency. This is especially useful on Wayland.

Install packages:

```bash
sudo pacman -S libva-mesa-driver libva-utils
```

Verify that VA-API is working:

```bash
vainfo
```

Expected output is a list of supported profiles and entrypoints, such as
`VAProfileH264Main` or `VAProfileVP9Profile0`. Empty output or an error means
the driver is not active.

## Hyprland Environment Variables

Add the following to `~/.config/hypr/lua/hyprconf/env.lua` to ensure correct
Wayland rendering and Mesa integration:

```conf
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# Force GBM backend and Mesa Vulkan driver for AMD
env = GBM_BACKEND,dri
env = __GLX_VENDOR_LIBRARY_NAME,mesa
```

Optional VRR or FreeSync setting:

```conf
misc {
    vrr = 1
}
```

## Performance Monitoring

`amdgpu_top` provides a real-time TUI showing GPU usage, VRAM, clocks, and
power draw.

```bash
sudo pacman -S amdgpu_top
amdgpu_top
```
