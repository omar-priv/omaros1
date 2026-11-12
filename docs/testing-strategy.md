# Testing strategy — Sadim OS

Updated: 12 November 2026.

The user selected direct ISO/USB testing. Do not run QEMU as part of this project's current acceptance path.

## Automated checks

1. Static CI parses all workflow YAML files.
2. CI runs sh -n / bash -n against project shell scripts.
3. CI rejects known invalid Buildroot symbols, the old --no-config Weston flag and the empty-hash Brave installer.
4. Buildroot make defconfig is followed by a check that every requested BR2_*=y symbol survived Kconfig.
5. Rootfs build verifies Weston, the QCA9377 firmware file and rootfs.squashfs.
6. ISO build verifies required boot files, hybrid BIOS metadata, embedded live/rootfs.squashfs and SHA256 before upload.

## What automated tests do not prove

A build or a Weston socket does not prove the custom UI, Wi-Fi, Realtek sound, touchpad, power management, idle RAM or disk-I/O performance. The custom Windows-like shell and graphical applications are not implemented yet.

## Hardware acceptance checklist

Only after a fresh reviewed ISO artifact exists:

- Confirm the correct USB device before writing; the USB stick will be erased.
- Boot using Acer F12 and Legacy BIOS.
- Confirm that the internal Windows disk is not mounted read-write.
- Confirm Live rootfs and Weston display.
- Test keyboard, touchpad, Intel graphics, USB, Ethernet, QCA9377 Wi-Fi, audio and battery.
- Confirm /dev/zram0 exists and /proc/swaps shows zRAM active.
- Measure idle RAM, boot time and disk I/O. Do not claim performance goals before measurement.

If any test fails, record the exact kernel log and service log and keep the issue open until fixed and retested.
