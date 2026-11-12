# Sadim OS (سديم)

Sadim OS is a source-built, x86_64 Live Linux system under development for an Acer Aspire E5-576G (i5-7200U, 4 GB RAM). It is built from a custom Linux kernel configuration, BusyBox initramfs and a Buildroot userland. It is not a kernel written from scratch and is not ready to replace Windows.

## Honest current status — 12 November 2026

There is **no reviewed ISO download yet**. The latest completed full ISO attempt was Run #17 (ID 43166896881, commit 9655561): the kernel build passed, but the Buildroot root-filesystem stage failed before completion. Initramfs, ISO creation, ISO verification, checksum generation and artifact upload were never reached.

A new full ISO attempt, Run #18 (ID 43202062317, source commit 4871d36), was triggered by the seatd/Weston source fixes. At the last status check it was still building the kernel; no ISO artifact existed yet.

The latest green static CI is Run #64 (ID 43202312525, commit 3f4028c). It checks workflow YAML, shell syntax, executable service modes and repository guards. It is not an ISO build and does not prove that the ISO boots.

A source review found a concrete GUI startup mismatch: the overlay tried to start `/usr/bin/seatd`, but Buildroot's seatd daemon option was not enabled. Weston was scheduled before the package-managed seatd service, and the custom group file lacked the `video` group required by that service. Commit 4871d36 enables the daemon, checks the generated service and video group, and orders startup as S70seatd → S75-weston. A successful full build and runtime verification are still required.

- Repository: https://github.com/omar-priv/omaros1
- Build history: https://github.com/omar-priv/omaros1/actions
- Latest ISO attempt: https://github.com/omar-priv/omaros1/actions/runs/43202062317
- The ISO workflow runs automatically after changes under `sadim/**`, can also be started manually, and does not cancel an already-running ISO build.

Do not flash any artifact unless a fresh ISO workflow completes successfully and publishes `sadim.iso`, `sadim.iso.sha256` and `BUILD-REPORT.txt`.

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

1. `sadim-ci` runs static YAML and shell-syntax checks.
2. The separate ISO workflow builds the kernel, Buildroot rootfs, initramfs and hybrid ISO, then verifies boot files, embedded firmware, SquashFS metadata and SHA-256.
3. The owner explicitly tests the resulting USB Live image on the Acer. The current ISO workflow does not certify real hardware compatibility.

An artifact is publishable only when its workflow is completed successfully and contains `sadim.iso`, `sadim.iso.sha256` and `BUILD-REPORT.txt`. Static CI success is not proof of an ISO build or hardware compatibility.

## License and reuse

The project reuses upstream Linux, BusyBox, Buildroot, Weston and other open-source components under their respective licenses. Custom project scripts and configuration are maintained in this repository. See `docs/adr/` and `docs/known-issues.md` for architecture and limitations.
