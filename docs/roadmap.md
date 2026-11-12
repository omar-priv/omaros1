# Sadim OS — Roadmap (honest implementation status)

Updated: 12 November 2026. A phase is not complete merely because a file or script exists. Completion requires a build and a relevant test.

| Phase | Scope | Actual status | Evidence / exit condition |
|---|---|---|---|
| 0 | Environment and hardware discovery | Documented | Hardware discovery notes; values still need confirmation on the laptop |
| 1 | Architecture and research | Documented | ADRs and research notes |
| 2 | Kernel + initramfs | Build scripts/config exist; latest kernel/initramfs steps passed in older Run #9 | Fresh build plus direct USB boot required |
| 3 | Live root filesystem | Config/overlay exist; invalid symbols corrected and a Kconfig retention gate added | Fresh Buildroot build and rootfs checks |
| 4 | Graphical compositor | Weston + seatd configured; startup waits for a real Wayland socket | Fresh build and real DRM display test on Acer |
| 5 | Native graphical applications | Not implemented | Build actual Wayland clients or a compatible toolkit desktop |
| 6 | Hardware support | Kernel options/firmware configured; no actual device certification | Verify i915, QCA9377, Realtek audio, input, USB and ACPI on Acer |
| 7 | Memory/storage tuning | zRAM config/service corrected; metrics are read-only | Verify zRAM, RAM and disk I/O on hardware |
| 8 | Daily Live ISO | Build workflow exists; current Run #9 is an older pre-review snapshot | Fresh reviewed build, ISO structure, SHA256 and artifact |
| 9 | Windows-like custom shell | Deferred; old scripts were terminal mockups | Native graphical shell and interaction tests |
| 10 | Browser and Windows app compatibility | Deferred; empty-hash Brave installer disabled; Chromium/Wine removed from base | Pinned browser package, integrity verification, GUI integration and security tests |
| 11 | Full desktop app suite | Not implemented; current scripts are terminal prototypes | Graphical file manager, editor, calculator, settings and task manager |
| 12 | System management tools | Some command-line prototypes exist; not certified | Functional and permission tests |
| 13 | Release hardening | In progress | Fresh ISO artifact + successful USB boot + hardware checklist |

## Measurable targets — not results

- Idle RAM: target under 1 GB, measured after 5 minutes at idle across 3 runs.
- Boot-to-desktop time: measure from firmware handoff to Weston socket/display readiness.
- Storage writes: inspect /proc/diskstats while idle. The Live system must not mount internal disks read-write.
- Arabic: verify font shaping, RTL layout and Alt+Shift switching on the actual display/input stack.

## Release gate

Do not call Sadim ready for daily use until a fresh reviewed ISO builds, the boot medium is verified, the Acer starts from USB without modifying Windows, and every advertised hardware/GUI feature is tested. A green static CI job alone is not a release gate.
