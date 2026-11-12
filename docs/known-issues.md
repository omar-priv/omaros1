# Known issues and release blockers

Updated: 12 November 2026. Items stay open until a fix and its relevant test both exist.

## Critical / release-blocking

- No reviewed ISO yet: the latest completed full ISO Run #17 (43166896881, commit 9655561) built the kernel but failed during the Buildroot root-filesystem stage. No initramfs, ISO or downloadable artifact was produced. Run #64 is static CI only, not an ISO build. Run #18 is the first full build using the seatd correction and remains subject to its actual final result.
- Seatd/Weston runtime ordering: source review found that Buildroot's seatd daemon was not enabled even though the overlay tried to launch it, Weston was ordered before the Buildroot-generated seatd service, and the custom group file omitted `video`. Source changes now enable the daemon and order S70seatd before S75-weston; these changes remain unverified until a successful Buildroot build and runtime test.
- GUI application gap: Weston is a compositor, not the finished Sadim desktop. The former taskbar, Start menu, file explorer, notes, calculator, settings and task-manager scripts are terminal prototypes, not native Wayland clients. The legacy taskbar launcher is disabled.
- Hardware compatibility unverified: no proof yet for Intel HD 620 DRM, QCA9377 Wi-Fi/firmware, Realtek audio, touchpad, ACPI/battery or USB boot on the Acer itself.

## High

- Buildroot uses a lean musl profile. Earlier Kconfig and optional text-shaping entries were corrected/removed; Run #17 still failed inside Buildroot before the final fatal line could be recovered from retained job output. Inspect the next Buildroot log from its first fatal error rather than assuming the earlier issue is still responsible.
- USB discovery race: init scans common optical, SATA/SCSI, virtio, NVMe and MMC device names for up to 20 seconds and attempts read-only mounts. Real USB boot still needs testing.
- Weston may still fail on the real Intel DRM/seat setup even after daemon ordering is fixed; inspect `/var/log/weston.log`.
- zRAM: kernel config builds zRAM in; the init service checks the actual block device and active swap. Needs fresh build and hardware verification. The service does not disable other swap devices.
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
