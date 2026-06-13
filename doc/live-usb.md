# Create Arch Linux Live USB

How to download the Arch Linux ISO, verify it, and write it to a USB drive on
Windows or Linux.

## Requirements

- A USB drive of at least 2 GB. All data will be erased.
- A machine with internet access.

## Download the ISO

Get the latest ISO from [archlinux.org/download][arch-download].
Pick a geographically close mirror for faster speeds, such as Tsinghua, BFSU,
or NetEase for China.

The download page also provides a **Torrent** and **Magnet link**. These are
often the fastest options if you have a torrent client.

## Verify the ISO

Verifying the ISO guards against a corrupted or tampered download.

On Windows PowerShell:

```powershell
Get-FileHash archlinux-x86_64.iso -Algorithm SHA256
```

Compare the output against the `sha256sums.txt` file on the download page.

On Linux:

```bash
sha256sum archlinux-x86_64.iso
```

Or use the PGP signature for a stronger check:

```bash
gpg --auto-key-retrieve --verify \
  archlinux-x86_64.iso.sig archlinux-x86_64.iso
```

A valid result shows a good signature from the current release signer. Ignore
the trust warning if the key is not in your local keyring.

## Write to USB on Windows

1. Download [Rufus][rufus] and open it.
1. Select your USB drive under **Device**.
1. Click **SELECT** and choose the Arch ISO.
1. Set **Partition scheme** to **GPT**.
1. Set **Target system** to **UEFI (non-CSM)**.
1. When prompted, choose **DD Image** mode instead of ISO Image mode.
1. Click **START**, then **OK** to confirm the drive will be wiped.

Using **ISO Image** mode may produce a non-bootable drive. Always choose
**DD Image** for Arch Linux.

## Write to USB on Linux

Identify your USB drive. Do not confuse it with your system disk:

```bash
lsblk
```

Write the ISO. Replace `/dev/sdX` with your actual USB device, such as
`/dev/sdb`:

```bash
sudo dd bs=4M if=archlinux-x86_64.iso of=/dev/sdX \
  conv=fsync oflag=direct status=progress
```

Wait for `dd` to finish and return to the prompt before unplugging the drive.
Double-check the target device. Writing to the wrong disk will destroy data.

## Ventoy Alternative

[Ventoy][ventoy] lets you store multiple ISOs on a single USB drive and boot
any of them from a menu. No re-flashing is needed.

Install Ventoy onto the USB on Linux:

```bash
# Download the latest release from https://github.com/ventoy/Ventoy/releases
tar -xf ventoy-*.tar.gz
cd ventoy-*
sudo ./Ventoy2Disk.sh -i /dev/sdX
```

The `-i` flag installs Ventoy. Use `-u` to update an existing Ventoy USB.

Install Ventoy onto the USB on Windows:

```text
Run Ventoy2Disk.exe from the extracted archive.
Select your USB drive.
```

Once installed, copy any `.iso` file directly onto the USB data partition.
Ventoy detects and lists them automatically at boot.

[arch-download]: https://archlinux.org/download/
[rufus]: https://rufus.ie
[ventoy]: https://www.ventoy.net
