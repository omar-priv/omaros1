# Known issues and release blockers

Updated: 12 November 2026. Items stay open until a fix and its relevant test both exist.

## Critical / release-blocking

- No reviewed ISO yet. Run #18 (43202062317, commit 4871d36) is an older build and was still in Buildroot at the last check. Current-source Run #20 (43203309978, commit 92f89dc) was queued and must finish its Buildroot, ISO structure and three-run QEMU gates before its artifact can be considered.
- Hardware compatibility remains unverified: there is no direct Acer test yet for Intel HD 620 DRM, QCA9377 Wi-Fi/firmware, Realtek audio, touchpad, ACPI/battery or USB boot.
- GUI application gap: Weston is a compositor, not the finished Sadim desktop. The former taskbar, Start menu, file explorer, notes, calculator, settings and task-manager scripts are terminal prototypes, not native Wayland clients. The legacy taskbar launcher is disabled.

## High

- Buildroot uses a lean musl profile. Earlier Kconfig and optional text-shaping entries were corrected/removed; Run #17 still failed inside Buildroot before its final fatal line could be recovered from retained job output. The newer seatd configuration is being tested by the current-source build.
- Weston may still fail on the real Intel DRM/seat setup even after daemon ordering is fixed; inspect `/var/log/weston.log`.
- QEMU smoke tests verify the virtualized BIOS/ISO path only; they do not certify the Acer's physical devices or firmware.
- zRAM: kernel config builds zRAM in; the init service checks the actual block device and active swap. Needs hardware verification. The service does not disable other swap devices.
- Brave installer: automatic network download is disabled. The old installer used an empty expected SHA256 and could install an unverified latest archive.
- Browser and Wine: intentionally deferred from the lightweight base; no working GUI integration was demonstrated.
- No UEFI claim: current ISO target is Legacy BIOS / hybrid USB only.

## Medium

- Performance targets (idle RAM, boot time, disk I/O) are not measured.
- Custom Arabic RTL desktop styling and application launchers are not implemented. Pango/HarfBuzz text shaping is intentionally deferred with the custom RTL UI; the current base is Weston desktop shell.
- `SADIM-GUI-OK` means only that Weston created a Wayland socket; it does not mean the custom desktop or apps are ready.

## Safety rules

- Never run `hdparm -W`, formatting, partitioning or automatic read-write mounts against `/dev/sda` or any guessed drive name.
- The Live OS must use a read-only SquashFS lower layer and tmpfs upper layer.
- Never claim hardware support without a test on the actual laptop.
