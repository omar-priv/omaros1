# Sadim OS — Project status

Last reviewed: 12 November 2026  
Repository: omar-priv/omaros1  
Target: Acer Aspire E5-576G, Intel i5-7200U, 4 GB RAM, HDD, Legacy BIOS  
Release state: development only; no reviewed downloadable ISO.

## Latest verified CI/build status

- Latest static CI: Run #64, ID 43202312525, commit 3f4028c — passed. It checks YAML, shell syntax, executable init services and static repository guards only; it does not compile Buildroot or create an ISO.
- Run #63 failed because a newly added CI assertion looked for the Weston service ordering in the wrong file. That assertion was corrected to check the init sequence in `rcS`; Run #64 passed.
- Latest full ISO attempt before the source fix: Run #17, ID 43166896881, commit 9655561 — failed during the Buildroot root-filesystem stage. The kernel stage passed. Initramfs, ISO creation, ISO verification, checksum generation and upload were not reached.
- New full ISO attempt: Run #18, ID 43202062317, source commit 4871d36 — started automatically after source changes. At the last status check it was building the Linux kernel. No artifact had been published.
- The ISO workflow is triggered by changes under `sadim/**`, is also manually triggerable, and uses `cancel-in-progress: false`. It has a 360-minute job timeout and saves source/compiler caches after success or failure.

## Confirmed source-review findings and fixes now in the tree

1. Live init retries block-device discovery for 20 seconds, searches optical, SATA/SCSI, virtio, NVMe and MMC device names, validates the mounted root and uses read-only mounts.
2. Weston uses the checked-in `weston.ini`, waits for its Wayland socket and fails visibly if startup fails.
3. The legacy terminal-only taskbar launcher is disabled; Weston desktop shell is the only current graphical shell.
4. Init service scripts are executable in Git and the initramfs builder restores executable permissions before creating the CPIO archive.
5. Buildroot validates that requested Kconfig `=y` symbols survive `make defconfig`; it checks Weston, QCA9377 firmware, BusyBox swap applets, service modes and SquashFS output.
6. **Seatd startup mismatch fixed in source, pending a full build:** Buildroot's `BR2_PACKAGE_SEATD_DAEMON` is now requested and required; `S20-seatd` preflights the generated `S70seatd`; Weston is moved to `S75-weston` so it starts after seatd. The custom group file now includes the Buildroot-standard `video` and `audio` groups, with the Sadim user in both.
7. Build order creates the Buildroot rootfs before initramfs. QCA9377 firmware is copied into initramfs because the built-in ath10k driver may request firmware before the full root is mounted.
8. Kernel zRAM is built in; the init service verifies that swap really becomes active and does not disable other swap devices.
9. The metrics service no longer invokes `drop_caches` under memory pressure.
10. The old Brave boot-time installer is disabled because its SHA256 was empty.
11. Storage tuning no longer targets `/dev/sda` or changes physical-drive write-cache settings.
12. Wired networking discovers the interface name dynamically; Wi-Fi does not claim association unless a saved WPA configuration exists.
13. Startup markers no longer claim that browser, Wine, custom Windows shell or hardware support have passed.
14. The ISO workflow checks bootloader files, embedded kernel/initramfs/SquashFS, QCA9377 firmware in initramfs, SquashFS metadata and checksum before upload.

## What remains incomplete or unverified

- A fresh full Buildroot/rootfs build after the seatd correction.
- A successful fresh ISO, checksum, report and downloadable artifact.
- Native Wayland GUI applications and the custom Sadim/Windows-like shell.
- Browser package with pinned version and verifiable checksum/signature; Wine support.
- Actual Acer hardware verification: display, Wi-Fi, audio, touchpad, USB boot, battery, thermals and suspend/power.
- Performance measurements on the target laptop.

## Release gate

A reviewed release requires a fresh ISO build after the changes above, successful ISO structure and SquashFS checks, a checksum and build report, then a Live USB trial on the Acer. Do not call the system hardware-certified before that direct test.
