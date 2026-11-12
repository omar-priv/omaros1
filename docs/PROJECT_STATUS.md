# Sadim OS — Project status

Last reviewed: 12 November 2026  
Repository: omar-priv/omaros1  
Target: Acer Aspire E5-576G, Intel i5-7200U, 4 GB RAM, HDD, Legacy BIOS  
Release state: development only; no reviewed downloadable ISO.

## Current build situation

- Run #9: 43147836495 — started from commit f1dc985 before the fixes in this review. It is retained and must finish independently.
- At the last live check, Run #9 had built the Linux kernel and initramfs; Buildroot rootfs was still running. No artifact existed.
- Run #9 is an older source snapshot; even if it later uploads an artifact, do not flash it as the reviewed image.
- The ISO workflow is manual-only and does not cancel another run. A new reviewed build must be dispatched explicitly after Run #9 finishes.
- Static CI for reviewed commit 82e1f76 passed. That verifies YAML, shell syntax, script executable modes and static guards only; it does not run Buildroot.

## Changes prepared after Run #9 started

1. Live init retries block-device discovery for 20 seconds, searches optical, SATA/SCSI, virtio, NVMe and MMC device names, validates the mounted root and uses read-only mounts.
2. Weston requires seatd, loads the checked-in weston.ini, waits for a Wayland socket and fails visibly if startup fails.
3. The misleading terminal-only taskbar launcher is disabled. Weston desktop shell is the only current graphical shell claim.
4. Init service scripts are executable in Git and the initramfs builder explicitly restores executable permissions before creating the CPIO archive.
5. Buildroot symbols were corrected. The configuration selects the 6.12 kernel headers through the supported BR2_KERNEL_HEADERS_6_12 choice, enables BusyBox alternatives for net-tools/procps-ng and uses the verified QCA9377, iproute2, net-tools and procps-ng options.
6. Buildroot validates that requested Kconfig y symbols survive make defconfig; the build checks Weston, the QCA9377 firmware, BusyBox swap applets, executable init services and SquashFS output.
7. Build order now creates the Buildroot rootfs before initramfs. QCA9377 firmware is copied into initramfs because the ath10k driver is built into the kernel and may request firmware before the full root is mounted.
8. Kernel zRAM is built in; the init service verifies that swap really becomes active and does not disable other swap devices.
9. The metrics service no longer invokes drop_caches under memory pressure.
10. The old Brave boot-time installer is disabled because its SHA256 was empty.
11. Storage tuning no longer targets /dev/sda or changes physical-drive write-cache settings.
12. Wired networking discovers the interface name dynamically; Wi-Fi reports an interface but does not claim association unless a saved WPA configuration exists.
13. Startup markers no longer claim that browser, Wine, custom Windows shell or hardware support have passed.
14. The ISO verification step checks bootloader files, embedded kernel/initramfs/SquashFS, QCA9377 firmware in initramfs, SquashFS metadata and checksum before upload.

## What remains incomplete

- Native Wayland GUI applications and the custom Sadim/Windows-like shell.
- Browser package with pinned version and verifiable checksum/signature.
- Wine support (not available in the previous x86_64 Buildroot profile).
- Actual Acer hardware verification: display, Wi-Fi, audio, touchpad, USB boot, battery, thermals and suspend/power.
- Performance measurements on the target laptop.
- A fresh reviewed ISO build, checksum, artifact download and a safe USB trial.

## Release gate

A reviewed release requires a fresh manual ISO build after these changes, successful ISO structure and SquashFS checks, a checksum and build report, and then a Live USB trial on the Acer. QEMU is not part of this project's acceptance path.
