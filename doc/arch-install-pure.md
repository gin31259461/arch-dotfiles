# Arch Linux Installation (Pure Arch)

Step-by-step guide for installing Arch Linux as the only operating system on a
UEFI/GPT machine.

References:

- [Arch Linux installation guide][arch-install]
- [ArchWiki GRUB][arch-grub]
- [ArchWiki EFI system partition][arch-esp]

## Prerequisites

- UEFI boot mode, not legacy BIOS.
- Secure Boot is disabled before booting the Arch ISO.
- The target disk can be erased.
- One EFI system partition (ESP), mounted at `/efi`.
- One dedicated partition for Arch root (`/`).
- Use a swap file instead of a swap partition.

> This guide destroys the existing partition table on the target disk. Back up
> anything important before continuing.

## Download ISO

Get the latest ISO from [archlinux.org/download][arch-download].
Use a mirror close to you, such as Tsinghua, BFSU, or NetEase.

If possible, verify the ISO signature before writing the installer USB.

## Create Bootable USB

Use [Rufus][rufus]:

- Write mode: **DD**.
- Partition scheme: **GPT**.

## BIOS Settings

Reboot into BIOS, such as **F12** on Dell, with the USB plugged in:

1. Disable **Secure Boot**.
1. If the target disk is not visible in Linux because the firmware uses RAID/RST,
   switch the disk controller mode to **AHCI**.
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

Identify the target disk, such as `/dev/nvme0n1` or `/dev/sda`. Do not continue
until the target disk is certain.

Set variables for the target disk and the two partitions you are about to
create:

```bash
DISK=/dev/nvme0n1
EFI_PART=/dev/nvme0n1p1
ROOT_PART=/dev/nvme0n1p2
```

Adjust these values before running any destructive command. For SATA disks,
partition names look like `/dev/sda1` and `/dev/sda2`.

Create a new GPT partition table and partitions:

```bash
cfdisk --zero "$DISK"
```

In `cfdisk`:

1. Select **gpt** for the label type.
1. Create a `1G` partition and set its type to **EFI System**.
1. Create a second partition using the remaining space and keep its type as
   **Linux filesystem**.
1. Select **Write**, type `yes`, and select **Quit**.

Recommended layout:

| Mount | Filesystem | Size | Notes |
| --- | --- | --- | --- |
| `/efi` | FAT32 | 1 GiB | EFI system partition |
| `/` | ext4 | Remaining | Arch root filesystem |
| swap | - | 4 GiB | Swap file on `/` |

Format the new partitions:

Recheck the variables before formatting:

```bash
echo "$DISK" "$EFI_PART" "$ROOT_PART"
```

```bash
mkfs.fat -F 32 "$EFI_PART"
mkfs.ext4 "$ROOT_PART"
```

Mount the partitions:

```bash
mount "$ROOT_PART" /mnt

mkdir /mnt/efi
mount "$EFI_PART" /mnt/efi
```

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
pacman -S grub efibootmgr mtools dosfstools base-devel linux-headers \
  reflector git
```

Install CPU microcode for the processor type:

```bash
# Intel CPU
pacman -S intel-ucode

# AMD CPU
pacman -S amd-ucode
```

Run only the command that matches the CPU.

Install GRUB and generate the config:

```bash
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg
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

After the bootstrap finishes, install all configured package groups:

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
[arch-esp]: https://wiki.archlinux.org/title/EFI_system_partition
[arch-grub]: https://wiki.archlinux.org/title/GRUB
[arch-install]: https://wiki.archlinux.org/title/Installation_guide
[rufus]: https://rufus.ie
