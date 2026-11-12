# Sadim OS (سديم)

Sadim OS is a source-built, x86_64 Live Linux system under development for an Acer Aspire E5-576G (i5-7200U, 4 GB RAM). It is built from a custom Linux kernel configuration, BusyBox initramfs and a Buildroot userland. It is not a kernel written from scratch and is not ready to replace Windows.

## Honest current status — 12 November 2026

There is currently **no reviewed ISO download**. The latest attempts have confirmed that the kernel builds successfully (Run #15 produced a 4,469,760-byte bzImage). Buildroot then caught two optional text-shaping packages that were incompatible with this deliberately lean musl profile. Those unused entries were removed; the next full build is running from commit 9655561. Static CI for that commit passed.

- Repository: https://github.com/omar-priv/omaros1
- Current build history: https://github.com/omar-priv/omaros1/actions
- Build policy: the ISO workflow starts automatically after changes under `sadim/**` and remains manually triggerable. It does not cancel an already-running ISO build.

Do not flash an artifact unless the ISO workflow completes successfully and publishes `sadim.iso`, `sadim.iso.sha256` and `BUILD-REPORT.txt`.

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

1. sadim-ci runs static YAML and shell-syntax checks.
2. The separate ISO workflow builds the kernel, initramfs, Buildroot rootfs and hybrid ISO, then verifies the ISO contents and checksum.
3. The owner explicitly tests the resulting USB Live image on the Acer. No QEMU test is part of the current acceptance path.

An artifact is publishable only when its workflow is completed successfully and contains sadim.iso, sadim.iso.sha256 and BUILD-REPORT.txt. CI success is not proof of hardware compatibility.

## License and reuse

The project reuses upstream Linux, BusyBox, Buildroot, Weston and other open-source components under their respective licenses. Custom project scripts and configuration are maintained in this repository. See docs/adr/ for architectural decisions and docs/known-issues.md for limitations.
