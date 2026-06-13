# Arch Linux Installation (Dual Boot)

Step-by-step guide for installing Arch Linux alongside Windows on a UEFI
system.

Reference: [Arch Linux dual-boot tutorial][reference].

## Prerequisites

- UEFI boot mode, not legacy BIOS
- Dual boot alongside Windows with the existing Windows EFI partition
- One dedicated partition for Arch root (`/`)
- Swap file instead of a swap partition

## Download ISO

Get the latest ISO from [archlinux.org/download][arch-download].
Use a mirror close to you, such as Tsinghua, BFSU, or NetEase.

## Disk Partitioning

Use **Windows Disk Management** to shrink an existing volume and leave
unallocated free space for Arch.

Recommended layout:

| Mount   | Filesystem | Notes                                           |
| ------- | ---------- | ----------------------------------------------- |
| `/boot` | FAT32      | Reuse existing Windows EFI partition            |
| `/`     | ext4       | New partition from free space, such as 250 GB   |
| swap    | -          | Swap file on `/`, not a separate partition      |

> If the Windows EFI partition is only 100 MB, consider expanding it first.
> AOMEI Partition Assistant in WinPE is one option.

## Create Bootable USB

Use [Rufus][rufus]:

- Write mode: **DD**, not ISO
- Partition scheme: **GPT**, not MBR

## BIOS Settings

Reboot into BIOS, such as **F12** on Dell, with the USB plugged in:

1. Disable **Secure Boot**.
1. If the target disk is NVMe, set the disk mode to **AHCI**.
1. Move the USB drive to the **top** of the boot order.

Save, exit, and boot into the Arch ISO.

## Check Network

```bash
ip a
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
pacman -Syyy
```

## Set Mirrors

```bash
nano /etc/pacman.d/mirrorlist
```

Press `Ctrl-W`, search `## China`, cut (`Ctrl-K`) a few nearby mirrors, and
paste (`Ctrl-U`) them at the top of the file. Remove the leading `#`, then save
with `Ctrl-X`, `Y`, and `Enter`.

## Disk Setup

Check current layout:

```bash
lsblk
```

Create the root partition from the unallocated free space:

```bash
cfdisk /dev/nvme0n1
```

Adjust the device name to match your disk. Select **New**, enter a size such as
`250G`, then select **Write**, type `yes`, and select **Quit**.

Format the new partition:

```bash
mkfs.ext4 /dev/nvme0n1p5
```

Adjust the partition number to match the output from `lsblk`.

Mount the partitions:

```bash
mount /dev/nvme0n1p5 /mnt

mkdir /mnt/boot
mount /dev/nvme0n1p2 /mnt/boot
```

The first command mounts the Arch root partition. The final command mounts the
Windows EFI partition.

## Install Base System

```bash
pacstrap /mnt base linux linux-firmware nano
```

Alternative kernels include `linux-lts`, `linux-zen`, and `linux-hardened`.

## Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

Verify that the generated output looks correct.

## Configure New System

Chroot into the new system:

```bash
arch-chroot /mnt
```

### Swap File

Use `dd` instead of `fallocate` to avoid sparse-file issues on ext4:

```bash
dd if=/dev/zero of=/swapfile bs=2048 count=1048576 status=progress
chmod 600 /swapfile
mkswap /swapfile
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

```text
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch.localdomain   arch
```

### Root Password

```bash
passwd
```

### Bootloader

Install required packages:

```bash
pacman -S grub efibootmgr networkmanager network-manager-applet dialog \
  wireless_tools wpa_supplicant os-prober mtools dosfstools ntfs-3g \
  base-devel linux-headers reflector git sudo
```

Install CPU microcode:

```bash
pacman -S intel-ucode   # Intel CPU
# pacman -S amd-ucode   # AMD CPU
```

Enable `os-prober` so GRUB detects Windows:

```bash
nano /etc/default/grub
# Add or uncomment:
# GRUB_DISABLE_OS_PROBER=false
```

Install GRUB and generate the config:

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg
```

## Exit and Reboot

```bash
exit
umount -a
reboot
```

Remove the USB drive when the screen goes blank.

## Activate Network

Log in as `root`, then:

```bash
systemctl enable --now NetworkManager
nmtui
```

Use `nmtui` to connect to Wi-Fi if needed.

## Create User

```bash
useradd -m -G wheel <username>
passwd <username>
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
```

## Install GPU Drivers

```bash
# Intel integrated; modesetting via mesa, xf86-video-intel not needed
pacman -S mesa

# AMD integrated / discrete
pacman -S xf86-video-amdgpu

# NVIDIA discrete
pacman -S nvidia nvidia-utils

# NVIDIA Optimus; switch between iGPU and dGPU
# sudo pacman -S optimus-manager
```

> **AMD users:** after booting into the installed system, follow the
> [AMD GPU Setup](amd-gpu.md) guide to verify drivers, enable Vulkan, configure
> VA-API hardware acceleration, and set Hyprland environment variables.

## Add archlinuxcn Repository

```bash
nano /etc/pacman.conf
```

Append this repository:

```ini
[archlinuxcn]
Server = https://mirrors.bfsu.edu.cn/archlinuxcn/$arch
```

Also uncomment the `[multilib]` section. Then run:

```bash
pacman -Syu
pacman -S archlinuxcn-keyring
```

Install Chinese fonts:

```bash
pacman -S noto-fonts-cjk ttf-sarasa-gothic
```

## Install Hyprland

Run the bootstrap script to deploy dotfiles, install Oh My Zsh, and optionally
install all dependencies in one step:

```bash
repo_url="https://raw.githubusercontent.com/gin31259461/arch-dotfiles"
curl -fsSL "$repo_url/main/.local/bin/bootstrap.sh" | bash
```

[arch-download]: https://archlinux.org/download/
[reference]: https://zhuanlan.zhihu.com/p/138951848
[rufus]: https://rufus.ie
