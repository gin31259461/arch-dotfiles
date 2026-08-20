# Arch Linux Installation (Dual Boot)

Step-by-step guide for installing Arch Linux alongside Windows on a UEFI/GPT
system.

References:

- [Arch Linux installation guide][arch-install]
- [ArchWiki dual boot with Windows][arch-dual-boot]
- [ArchWiki GRUB][arch-grub]

## Prerequisites

- Windows is already installed in UEFI mode on a GPT disk.
- Secure Boot is disabled before booting the Arch ISO.
- Windows Fast Startup and hibernation are disabled before resizing or sharing
  disks.
- BitLocker or Device Encryption recovery keys are saved before changing
  firmware, Secure Boot, or partition settings.
- One dedicated partition for Arch root (`/`).
- Reuse the existing Windows EFI system partition (ESP), mounted at `/efi`.
- Use a swap file instead of a swap partition.

## Download ISO

Get the latest ISO from [archlinux.org/download][arch-download].
Use a mirror close to you, such as Tsinghua, BFSU, or NetEase.

If possible, verify the ISO signature before writing the installer USB.

## Prepare Windows

From Windows:

1. Confirm **BIOS Mode** is `UEFI` in `msinfo32`.
1. Save the BitLocker or Device Encryption recovery key, if encryption is
   enabled.
1. Disable Fast Startup and hibernation:

   ```powershell
   powercfg /H off
   ```

1. Use **Windows Disk Management** to shrink an existing volume and leave
   unallocated free space for Arch.

Do not delete Windows recovery, EFI, Microsoft Reserved, or Windows data
partitions.

Recommended layout:

| Mount | Filesystem | Notes |
| --- | --- | --- |
| `/efi` | FAT32 | Existing Windows EFI system partition |
| `/` | ext4 | New partition from free space, such as 250 GB |
| swap | - | Swap file on `/`, not a separate partition |

The Windows ESP is often small. Mounting it at `/efi` keeps the Arch kernel and
initramfs in `/boot` on the root filesystem instead of filling the ESP.

## Create Bootable USB

Use [Rufus][rufus]:

- Write mode: **DD**.
- Partition scheme: **GPT**.

## BIOS Settings

Reboot into BIOS, such as **F12** on Dell, with the USB plugged in:

1. Disable **Secure Boot**.
1. If the target disk is not visible in Linux because the firmware uses RAID/RST,
   prepare Windows for AHCI first, then switch the disk controller mode to
   **AHCI**. Changing this setting without preparing Windows can make Windows
   fail to boot.
1. Boot the USB drive in UEFI mode.

Save, exit, and boot into the Arch ISO.

## Check Boot Mode

Verify that the installer booted in UEFI mode:

```bash
cat /sys/firmware/efi/fw_platform_size
```

The command should print `64`. If it prints an error, reboot and choose the UEFI
entry for the USB drive.

## Check Network

List interfaces:

```bash
ip link
```

For wired networking, the connection should be automatic.

For wireless networking, use `iwctl`:

```bash
iwctl
device list                       # note interface name, e.g. wlan0
station wlan0 scan
station wlan0 get-networks
station wlan0 connect <SSID>      # enter password when prompted
exit
```

Verify connectivity:

```bash
ping -c 3 archlinux.org
```

Check that the system clock is synchronized:

```bash
timedatectl
```

## Set Mirrors

```bash
nano /etc/pacman.d/mirrorlist
```

Press `Ctrl-W`, search for nearby mirrors, cut (`Ctrl-K`) a few preferred
mirrors, and paste (`Ctrl-U`) them at the top of the file. Remove the leading
`#`, then save with `Ctrl-X`, `Y`, and `Enter`.

## Disk Setup

Check current layout:

```bash
lsblk -f
```

Identify:

- The new Arch root partition, such as `/dev/nvme0n1p5`.
- The existing Windows ESP, usually a small FAT32 partition such as
  `/dev/nvme0n1p1` or `/dev/nvme0n1p2`.

If the Arch root partition does not exist yet, create it from the unallocated
free space:

```bash
cfdisk /dev/nvme0n1
```

Adjust the device name to match your disk. Select **New**, enter a size such as
`250G`, then select **Write**, type `yes`, and select **Quit**.

Format only the new Arch root partition:

```bash
mkfs.ext4 /dev/nvme0n1p5
```

Do not format the existing Windows ESP.

Mount the partitions:

```bash
mount /dev/nvme0n1p5 /mnt

mkdir /mnt/efi
mount /dev/nvme0n1p2 /mnt/efi
```

Adjust both partition numbers to match `lsblk -f`.

## Install Base System

```bash
pacstrap -K /mnt base linux linux-firmware nano networkmanager sudo
```

Alternative kernels include `linux-lts`, `linux-zen`, and `linux-hardened`.
Install matching headers when needed, for example `linux-headers` for the
default kernel.

## Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

Verify that `/` and `/efi` point to the expected partitions.

## Configure New System

Chroot into the new system:

```bash
arch-chroot /mnt
```

### Swap File

Create and enable a 4 GiB swap file:

```bash
mkswap -U clear --size 4G --file /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab
```

### Timezone

```bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
```

### Locale

```bash
nano /etc/locale.gen
# Uncomment: en_US.UTF-8 UTF-8 and zh_CN.UTF-8 UTF-8
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

### Hostname

```bash
echo 'arch' > /etc/hostname
```

### Hosts

Edit `/etc/hosts`:

```bash
nano /etc/hosts
```

```text
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch.localdomain   arch
```

### Root Password

```bash
passwd
```

### User

```bash
useradd -m -G wheel <username>
passwd <username>
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
```

### Bootloader

Install required packages:

```bash
pacman -S grub efibootmgr os-prober mtools dosfstools ntfs-3g fuse3 \
  base-devel linux-headers reflector git
```

Install CPU microcode for the processor type:

```bash
# Intel CPU
pacman -S intel-ucode

# AMD CPU
pacman -S amd-ucode
```

Run only the command that matches the CPU.

Enable `os-prober` so GRUB can detect Windows:

```bash
nano /etc/default/grub
# Add or uncomment this active line:
# GRUB_DISABLE_OS_PROBER=false
```

The final line must not start with `#`:

```text
GRUB_DISABLE_OS_PROBER=false
```

Install GRUB and generate the config:

```bash
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg
```

The `grub-mkconfig` output should mention Windows Boot Manager. If it does not,
finish the install, boot Arch, confirm `/efi` is mounted, then run:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Enable Network

Enable NetworkManager before the first reboot:

```bash
systemctl enable NetworkManager
```

## Exit and Reboot

```bash
exit
umount -R /mnt
reboot
```

Remove the USB drive when the screen goes blank.

## Activate Network

Log in, then connect to Wi-Fi if needed:

```bash
sudo nmtui
```

## Install GPU Drivers

Install the driver stack that matches the hardware.

Common userspace OpenGL/Vulkan support:

```bash
sudo pacman -S mesa vulkan-icd-loader
```

AMD integrated or discrete GPU:

```bash
sudo pacman -S vulkan-radeon
```

Intel integrated GPU:

```bash
sudo pacman -S vulkan-intel
```

NVIDIA discrete GPU, matching the default `linux` kernel:

```bash
sudo pacman -S nvidia-open nvidia-utils
```

For `linux-lts`, use `nvidia-open-lts`. For custom kernels, use
`nvidia-open-dkms` and the matching kernel headers. Older NVIDIA GPUs may need a
legacy proprietary driver instead; check the ArchWiki NVIDIA page before
installing on pre-Turing hardware.

> **AMD users:** after booting into the installed system, follow the
> [AMD GPU Setup](amd-gpu.md) guide to verify drivers, enable Vulkan, configure
> VA-API hardware acceleration, and set Hyprland environment variables.

## Add archlinuxcn Repository

Edit pacman configuration:

```bash
sudo nano /etc/pacman.conf
```

Append this repository:

```ini
[archlinuxcn]
Server = https://mirrors.bfsu.edu.cn/archlinuxcn/$arch
```

Also uncomment the `[multilib]` section if you need 32-bit libraries. Then run:

```bash
sudo pacman -Sy archlinuxcn-keyring
sudo pacman -Syu
```

Install Chinese fonts:

```bash
sudo pacman -S noto-fonts-cjk ttf-sarasa-gothic
```

## Install Dotfiles and Hyprland

Install Homebase and bootstrap this dotfiles repository:

```bash
url=https://raw.githubusercontent.com/gin31259461/homebase/main/bootstrap
curl -fsSL "$url/archlinux.sh" | \
  bash -s -- --repo gin31259461/dotfiles-arch
```

After the bootstrap finishes, install all configured install groups:

```bash
hb install --all
```

If `hb` was installed separately without bootstrapping this repository, run
`hb bootstrap` before `hb install`.

For unattended installation, pass `--yes` with an explicit selection:

```bash
hb install --all --yes
```

[arch-download]: https://archlinux.org/download/
[arch-dual-boot]: https://wiki.archlinux.org/title/Dual_boot_with_Windows
[arch-grub]: https://wiki.archlinux.org/title/GRUB
[arch-install]: https://wiki.archlinux.org/title/Installation_guide
[rufus]: https://rufus.ie
