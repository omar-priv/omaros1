# Sadim OS — Project status

Last reviewed: 12 November 2026  
Repository: omar-priv/omaros1  
Target: Acer Aspire E5-576G, Intel i5-7200U, 4 GB RAM, HDD, Legacy BIOS  
Release state: development only; no reviewed downloadable ISO.

## Current build situation

- Run #9: 43147836495 — started from commit f1dc985 before the fixes in this review. It is retained and must finish independently.
- Run #9 had built the Linux kernel and initramfs successfully; its Buildroot root filesystem was still running at the last confirmed check.
- It has no reviewed artifact and does not include the changes in this review.
- The ISO workflow is now manual-only and does not cancel another run. A new reviewed build must be dispatched explicitly after the current run finishes.

## Changes prepared in the repository after Run #9 started

1. Live init retries block-device discovery for 20 seconds, searches SATA/SCSI/optical/virtio/NVMe/MMC device names, validates the mounted root and uses read-only mounts.
2. Weston requires seatd, loads the configured weston.ini, waits for the Wayland socket and fails visibly if startup fails.
3. The misleading terminal-only taskbar launcher is disabled. Weston desktop shell is the only current graphical shell claim.
4. Buildroot symbols were corrected: QCA9377 firmware, iproute2, net-tools and procps-ng; unsupported/incorrect Chromium, Wine and package zRAM settings were removed from the base profile.
5. Buildroot now validates that requested Kconfig y symbols survive make defconfig, and checks for Weston, QCA9377 firmware and the SquashFS image.
6. Kernel zRAM is built in; the init service verifies that swap really becomes active and does not disable other swap devices.
7. The metrics service no longer invokes drop_caches under memory pressure.
8. The old Brave boot-time installer is disabled because its SHA256 was empty.
9. Storage tuning no longer targets /dev/sda or changes physical-drive write-cache settings.
10. Startup markers no longer claim that browser, Wine, custom Windows shell or hardware support have passed.

## What remains incomplete

- Native Wayland GUI applications and the custom Sadim/Windows-like shell.
- Browser package with pinned version and verifiable checksum/signature.
- Wine support (also unavailable in the old x86_64 Buildroot profile).
- Actual Acer hardware verification: display, Wi-Fi, audio, touchpad, USB boot, battery, thermals and suspend/power.
- Performance measurements on the target laptop.
- New reviewed ISO build, checksum, artifact download and a safe USB trial.

## Release gate

A reviewed release requires a fresh manual ISO build after these changes, successful ISO structure and SquashFS checks, a checksum and build report, and then a Live USB trial on the Acer. QEMU is not part of this acceptance path.
