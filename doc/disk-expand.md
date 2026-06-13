# Expand an Arch Linux Partition Online

Grow a root partition while the system is running, without a Live USB.
This works because `parted` and `cfdisk` can modify partition tables without
unmounting, and ext4, Btrfs, and XFS all support online filesystem growth.

## Prerequisites

- The free space, or partitions you plan to delete, must be located after the
  target Arch partition on the same disk. Use `lsblk` to confirm this.
- The target filesystem must support online growth: **ext4**, **Btrfs**, or
  **XFS**. Use `lsblk -f` to check which one you have.
- You do not need to unmount the partition or boot from a Live USB.

Choose a strategy before starting:

- **Option A:** Unwanted partitions, such as Windows recovery partitions, sit
  between the Arch root and free space. Delete them to claim a larger block.
- **Option B:** Only a small block of unallocated space sits directly after the
  Arch partition. Extend into it without touching anything else.

## Check Current Layout

```bash
lsblk -f
```

Confirm:

- The device name of your disk, such as `/dev/nvme0n1`
- The partition number of your Arch root, such as `p6`
- The filesystem type is `ext4`, `btrfs`, or `xfs`
- What sits between the Arch partition and the end of the disk

```bash
sudo parted /dev/nvme0n1 print free
```

The `print free` output shows unallocated gaps between partitions. Use it to
decide which option to use.

## Resize the Partition

### Option A: Delete Partitions Behind Arch Root

Open `parted` interactively. Adjust the device name as needed:

```bash
sudo parted /dev/nvme0n1
```

```text
(parted) print
(parted) rm 4
(parted) rm 5
(parted) resizepart 6
Warning: Partition /dev/nvme0n1p6 is being used.
Are you sure you want to continue?
Yes/No? yes
End? [250GB]? 100%
(parted) quit
```

Notes:

- `print` confirms partition numbers before deleting anything.
- `rm 4` and `rm 5` delete unwanted partitions, such as recovery partitions.
- `resizepart 6` extends the Arch root partition. Adjust the number.
- `100%` uses all free space after the partition.

Deleting Windows recovery partitions permanently disables factory restore.
Only do this if you no longer need Windows or its OEM recovery tools.

### Option B: Extend Into Adjacent Space Only

Use `parted` the same way as Option A, but skip the `rm` commands:

```bash
sudo parted /dev/nvme0n1
```

```text
(parted) print
(parted) resizepart 6
Warning: Partition /dev/nvme0n1p6 is being used.
Are you sure you want to continue?
Yes/No? yes
End? [250GB]? 100%
(parted) quit
```

Alternatively, `cfdisk` provides a more visual interface:

```bash
sudo cfdisk /dev/nvme0n1
```

Select the partition, choose **Resize**, press `Enter`, choose **Write**, type
`yes`, and choose **Quit**.

## Refresh the Kernel Partition Table

Tell the kernel to re-read the updated partition boundaries:

```bash
sudo partprobe /dev/nvme0n1
sudo udevadm settle
```

If `partprobe` reports that the partition is still busy, reboot before
proceeding. After rebooting, continue with filesystem expansion.

## Expand the Filesystem

The partition boundary has moved, but the filesystem still occupies its old
size. Use the command matching your filesystem type. Check with `lsblk -f`.

For ext4:

```bash
sudo resize2fs /dev/nvme0n1p6
```

Example output:

```text
resize2fs 1.47.0
Filesystem at /dev/nvme0n1p6 is mounted on /; on-line resizing required
old_desc_blocks = 4, new_desc_blocks = 18
The filesystem on /dev/nvme0n1p6 is now 36700160 (4k) blocks long.
```

For Btrfs:

```bash
sudo btrfs filesystem resize max /
```

For XFS, which can grow but cannot shrink:

```bash
sudo xfs_growfs /
```

All three commands are safe to run on a live, mounted filesystem.

## Verify the Result

```bash
df -hT /
lsblk -f /dev/nvme0n1
```

The `df` output should show the increased `Size` and `Avail` for the root
filesystem. `lsblk` confirms the new partition size matches expectations.
