# Sadim OS (سديم)

Sadim OS is a source-built, x86_64 Live Linux system under development for an Acer Aspire E5-576G (i5-7200U, 4 GB RAM). It is built from a custom Linux kernel configuration, BusyBox initramfs and a Buildroot userland. It is not a kernel written from scratch and is not ready to replace Windows.

## Honest current status — 12 November 2026

There is **no reviewed ISO download yet**.

- Latest static CI: Run #67 (ID 43203309994, commit 92f89dc) — passed. This validates source-level guards and shell syntax, not the generated ISO.
- Older ISO Run #18 (ID 43202062317, source commit 4871d36) — the kernel passed and Buildroot was still running at the last check. This run predates the network/monitor fixes and the QEMU acceptance gate. Do not treat any artifact from it as the reviewed image.
- Current full ISO Run #20 (ID 43203309978, source commit 92f89dc) — queued behind Run #18. This is the first build containing the seatd, udev/network and monitor corrections and the QEMU boot-test gate. No artifact had been published at the last check.

A source review identified and corrected several runtime issues: Buildroot's seatd daemon was not enabled even though the overlay tried to start it; Weston was scheduled before the package-managed seatd service; the custom group file lacked `video`; wired networking ran before eudev discovery; the monitor interval and driver-name variables were incorrectly escaped. The latest source enables seatd, orders S70seatd → S75-weston, starts network discovery after S10udev, and validates the relevant runtime files.

The ISO workflow now runs the hybrid image through SeaBIOS/ISOLINUX in QEMU three consecutive times and requires five runtime markers: boot, Live root, rootfs services, DHCP network, and Weston. Only after that gate passes are SHA-256 and build-report files generated and the artifact uploaded.

- Repository: https://github.com/omar-priv/omaros1
- Build history: https://github.com/omar-priv/omaros1/actions
- Current full ISO attempt: https://github.com/omar-priv/omaros1/actions/runs/43203309978

The ISO workflow runs automatically after changes under `sadim/**`, can also be started manually, and does not cancel an already-running ISO build. Do not flash an artifact unless a current-source run completes successfully and publishes `sadim.iso`, `sadim.iso.sha256` and `BUILD-REPORT.txt`.

## What the current base aims to provide

- Legacy BIOS hybrid ISO for USB Live use.
- Linux kernel with Intel graphics, USB storage, common input, network, audio and ACPI options built in.
- Read-only SquashFS system with a RAM-backed OverlayFS upper layer.
- Weston DRM compositor using the desktop shell and pixman renderer.
- BusyBox init and small system services.
- Diagnostic and terminal utility prototypes.

## What is not complete

- The custom Windows-like Sadim desktop, taskbar and graphical Start menu are not implemented. The former taskbar and app scripts are terminal prototypes and are no longer launched as if they were GUI applications.
- The existing file manager, notes, calculator, settings and task-manager scripts are not native graphical apps.
- Chromium and Wine are not included in the reviewed base. Brave auto-download is disabled until a pinned, integrity-checked package is available.
- Wi-Fi, audio, touchpad, display, battery, zRAM and application compatibility have not been verified on the actual Acer hardware.
- Performance targets (idle RAM, boot time and disk I/O) have not been measured on the laptop.

## Safety model

The intended release is Live-only. The boot init scans candidate devices and attempts read-only mounts to locate the ISO/SquashFS. It does not partition, format, install to, or mount an internal disk read-write. The writable system layer is tmpfs in RAM and is lost after shutdown. Do not use any installer or partitioning tool; none is part of this project.

The USB writer will erase the selected USB stick. Use an empty spare stick and verify its drive letter/device carefully.

## Build and test policy

1. `sadim-ci` checks workflow YAML, shell syntax and source-level boot guards.
2. The ISO workflow builds the kernel, Buildroot rootfs, initramfs and hybrid ISO, verifies its contents and firmware, then boots the actual ISO in QEMU three times before creating checksums and uploading.
3. The owner still needs to test the resulting USB Live image on the Acer. QEMU is a reproducible smoke test, not proof of real hardware compatibility.

An artifact is publishable only when its current-source ISO workflow is completed successfully and contains `sadim.iso`, `sadim.iso.sha256` and `BUILD-REPORT.txt`. Static CI success is not proof of an ISO build or hardware compatibility.

## License and reuse

The project reuses upstream Linux, BusyBox, Buildroot, Weston and other open-source components under their respective licenses. Custom project scripts and configuration are maintained in this repository. See `docs/adr/` and `docs/known-issues.md` for architecture and limitations.
