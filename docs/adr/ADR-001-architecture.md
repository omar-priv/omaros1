# ADR-001: Sadim OS architecture

- Status: Accepted — 12 November 2026
- Decision: Sadim is a source-built x86_64 Live Linux system using an upstream Linux kernel, a custom configuration/initramfs, Buildroot userland and Weston as the first compositor.
- Target: Acer Aspire E5-576G (i5-7200U, 4 GB RAM, Legacy BIOS).
- Safety invariant: the release is Live-only; it does not install or write to the internal Windows disk.

## Reused components

| Component | Role |
|---|---|
| Linux mainline kernel | Hardware support and process/memory/filesystem primitives |
| BusyBox | Initramfs utilities and init |
| Buildroot | Reproducible cross-built userland and root filesystem |
| musl | C library for target userland |
| Weston / Wayland | Initial DRM compositor and desktop shell |
| linux-firmware | Required firmware blobs for supported devices |

The kernel is not written from scratch. The project customizes and builds the upstream kernel and its surrounding system.

## Live boot design

1. BIOS boots the hybrid USB image through ISOLINUX.
2. The kernel starts the BusyBox initramfs.
3. Init waits for storage discovery and locates the ISO or SquashFS root filesystem using read-only mounts.
4. The root filesystem is mounted read-only; a tmpfs upper layer provides volatile writes.
5. switch_root enters the merged Live system.
6. seatd and Weston start; a compositor socket is required for the GUI startup marker.

No internal disk is mounted read-write. Do not add automatic disk tuning or partition operations based on guessed device names.

## Test policy

The user explicitly chose direct ISO and USB testing instead of QEMU. Static CI and the ISO builder may verify syntax, package configuration, ISO layout, checksums and SquashFS metadata. They do not prove that the Acer display, Wi-Fi, sound, touchpad or battery works. The release is not accepted until a verified Live USB is tested on the actual device.

## Current scope boundary

The first graphical stage is Weston desktop shell. It is not a custom Windows-like desktop. The current application scripts are terminal prototypes; native graphical apps, a custom panel/launcher, browser packaging and Wine are deferred until there is a working Wayland client toolkit and test suite.
