# Known issues and release blockers

Updated: 12 November 2026. Items stay open until a fix and its relevant test both exist.

## Critical / release-blocking

- GUI application gap: Weston is a compositor, not the finished Sadim desktop. The former taskbar, Start menu, file explorer, notes, calculator, settings and task-manager scripts are terminal prototypes, not native Wayland clients. The legacy taskbar launcher is disabled. A real graphical desktop/application suite remains unimplemented.
- No reviewed ISO yet: Run #15 built the kernel, but its Buildroot configuration gate correctly stopped before producing a root filesystem. The unused HarfBuzz/FriBidi entries were removed; the current full build attempt must still finish and publish a verified artifact before any USB trial.
- Hardware compatibility unverified: no current proof for Intel HD 620 DRM, QCA9377 Wi-Fi/firmware, Realtek audio, touchpad, ACPI/battery or USB boot on the Acer itself.

## High

- Buildroot configuration needed correction: earlier symbols for QCA9377 firmware, UPower, procps, IP tools and interface tools were corrected. The Kconfig retention gate now catches dropped options. Run #15 exposed two optional, unused text-shaping entries that did not fit the lean musl toolchain; they were removed rather than enabling C++ and increasing the base image before the Arabic UI exists. A fresh full rootfs build is still required.
- USB discovery race: init now scans common optical, SATA/SCSI, virtio, NVMe and MMC device names for up to 20 seconds, mounting candidates read-only. Real USB boot still needs testing.
- Weston startup: startup now waits for seatd and a Wayland socket and uses the config file instead of --no-config. Weston may still fail on the real Intel DRM/seat setup; inspect /var/log/weston.log.
- zRAM: kernel config now builds zRAM in; the init service checks the actual block device and active swap. Needs fresh build verification. The service no longer disables other swap devices.
- Brave installer: automatic network download is disabled. The old installer used an empty expected SHA256 and could install an unverified latest archive.
- Browser and Wine: intentionally deferred from the lightweight base; no working GUI integration was demonstrated.
- No UEFI claim: current ISO is Legacy BIOS / hybrid USB only.

## Medium

- Performance targets (idle RAM, boot time, SMR I/O) are not measured.
- Custom Arabic RTL desktop styling and application launchers are not implemented. Pango/HarfBuzz text shaping is intentionally deferred with the custom RTL UI; the current base is Weston’s desktop shell.
- SADIM-GUI-OK means only that Weston created a Wayland socket; it does not mean the custom desktop or apps are ready.

## Safety rules

- Never run hdparm -W, formatting, partitioning or automatic read-write mounts against /dev/sda or any guessed drive name.
- The Live OS must use a read-only SquashFS lower layer and tmpfs upper layer.
- Never claim hardware support without a test on the actual laptop.
