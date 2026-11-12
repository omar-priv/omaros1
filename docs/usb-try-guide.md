# Sadim OS — Live USB trial guide

**Status: not yet ready to flash.** No ISO has passed the current build and verification workflow yet. Run #15 built the kernel but stopped at Buildroot configuration; optional unused text-shaping packages were removed, and a newer full build is in progress. Do not use an older artifact as the reviewed build. Check [GitHub Actions](https://github.com/omar-priv/omaros1/actions) for the latest result.

When a new reviewed artifact appears, use these steps:

## Before flashing

1. Download sadim.iso, sadim.iso.sha256 and BUILD-REPORT.txt from the successful reviewed GitHub Actions artifact.
2. Verify the ISO checksum on Windows PowerShell with: Get-FileHash .\sadim.iso -Algorithm SHA256
3. Compare the displayed hash with the value in sadim.iso.sha256.
4. Use an empty USB stick. Writing the image erases that USB stick.

## Write the USB

Use Rufus or balenaEtcher. In Rufus select the USB device, choose sadim.iso, select MBR / BIOS (or UEFI-CSM) where offered, then choose DD Image mode if Rufus asks. Double-check the selected USB drive letter and capacity before confirming.

## Boot the Acer

1. Keep the laptop's internal drive untouched.
2. Insert the USB and power on.
3. Open the boot menu with F12 and select the USB device.
4. Select the normal Sadim Live option. The safe option disables ACPI/APIC for troubleshooting.
5. Do not select any installer or partitioning program. This project has no installer.

## What is expected at this stage

The initial target is a Live system with a Weston desktop shell. The custom Windows-like desktop and graphical app suite are not finished. The command-line utilities are prototypes and may require a terminal. Network, sound, touchpad and battery indicators still require real-hardware verification.

## Safety and shutdown

The intended system is read-only SquashFS plus a temporary RAM overlay. Internal disks must not be mounted read-write or modified. If you see a partitioning/format prompt, stop and power off.

Use poweroff from a console to shut down. Report boot errors, a blank display, a missing Wayland socket or hardware that does not appear.
