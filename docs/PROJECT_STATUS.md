# Sadim OS — Project status

Last reviewed: 12 November 2026  
Repository: omar-priv/omaros1  
Target: Acer Aspire E5-576G, Intel i5-7200U, 4 GB RAM, HDD, Legacy BIOS  
Release state: development only; no reviewed downloadable ISO.

## Latest verified CI/build status

- Latest static CI: Run #67, ID 43203309994, commit 92f89dc — passed. This verifies source guards and shell syntax; it does not build or boot an ISO.
- Run #18, ID 43202062317, source commit 4871d36 — older build. The kernel passed and Buildroot was still running at the last check. It predates the network/monitor fixes and QEMU boot gate; do not use its artifact as the reviewed image.
- Run #20, ID 43203309978, source commit 92f89dc — current-source build queued behind Run #18. It contains the latest fixes and the QEMU boot acceptance step. No artifact was available at the last check.
- Run #19 was superseded while pending by the newer queued run; it was cancelled by GitHub's concurrency queue, not by a code failure.
- The ISO workflow is triggered by changes under `sadim/**`, is also manually triggerable, and uses `cancel-in-progress: false`. It has a 360-minute job timeout and saves source/compiler caches after success or failure.

## Confirmed source-review fixes

1. Live init retries block-device discovery for 20 seconds, searches optical, SATA/SCSI, virtio, NVMe and MMC device names, validates the mounted root and uses read-only mounts.
2. Buildroot's seatd daemon is explicitly enabled and required. `S20-seatd` preflights the generated `S70seatd`; Weston is started by `S75-weston` after seatd. The custom group file includes the Buildroot-standard `video` and `audio` groups with the Sadim user in both.
3. Wired network discovery now runs in `S25-network`, after Buildroot's `S10udev` has populated devices and settled events. The Buildroot post-build checks require both scripts.
4. The monitor's default interval is now a real numeric 300 seconds (with invalid custom values reset to 300), rather than a literal escaped variable expression that could spin.
5. The driver-report script now expands its label and sysfs path variables correctly.
6. Buildroot validates that requested Kconfig `=y` symbols survive `make defconfig`; it checks Weston, seatd, udev, service modes, QCA9377 firmware, BusyBox swap applets and SquashFS output.
7. Build order creates the Buildroot rootfs before initramfs. QCA9377 firmware is copied into initramfs because the built-in ath10k driver may request firmware before the full root is mounted.
8. Kernel zRAM is built in; the init service verifies that swap really becomes active and does not disable other swap devices.
9. The metrics service no longer invokes `drop_caches` under memory pressure. Storage tuning does not target `/dev/sda` or change physical-drive write-cache settings.
10. The old Brave boot-time installer is disabled because its SHA256 was empty. Wi-Fi does not claim association unless a saved WPA configuration exists.
11. The custom terminal-only taskbar launcher is disabled; Weston desktop shell is the only current graphical shell claim.
12. The ISO workflow validates bootloader files, embedded kernel/initramfs/SquashFS and firmware, then runs three consecutive SeaBIOS/ISOLINUX QEMU boots requiring five markers before checksums and artifact upload.

## What remains incomplete or unverified

- Completion of the current-source Run #20 Buildroot/rootfs stage and later ISO stages.
- A successful QEMU boot gate, SHA-256, build report and downloadable ISO artifact.
- Native Wayland GUI applications and the custom Sadim/Windows-like shell.
- Browser package with pinned version and verifiable checksum/signature; Wine support.
- Actual Acer hardware verification: display, Wi-Fi, audio, touchpad, USB boot, battery, thermals and suspend/power.
- Performance measurements on the target laptop.

## Release gate

A reviewed release requires a successful current-source ISO workflow including the three-run QEMU boot test, verified ISO structure and SquashFS, checksum and build report, then a Live USB trial on the Acer. Do not call the system hardware-certified before that direct test.
