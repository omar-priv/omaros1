#!/usr/bin/env bash
# Build a hybrid Legacy-BIOS ISO for Live USB use. No installer is included.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
ISODIR="$OUT/iso-staging"
ISO_LABEL="SADIM_02_DAILY"

[ -s "$OUT/bzImage" ] || { echo "FAIL: bzImage missing"; exit 1; }
[ -s "$OUT/initramfs.cpio.gz" ] || { echo "FAIL: initramfs missing"; exit 1; }
[ -s "$OUT/rootfs.squashfs" ] || { echo "FAIL: rootfs.squashfs missing"; exit 1; }

rm -rf "$ISODIR"
mkdir -p "$ISODIR/boot" "$ISODIR/isolinux" "$ISODIR/live" "$ISODIR/sadim"
cp "$OUT/bzImage" "$ISODIR/boot/vmlinuz-sadim"
cp "$OUT/initramfs.cpio.gz" "$ISODIR/boot/initramfs-sadim.img"
cp "$OUT/rootfs.squashfs" "$ISODIR/live/rootfs.squashfs"

LOCALVERSION="$(awk -F '"' '/^CONFIG_LOCALVERSION=/{print $2}' "$ROOT/kernel/fragments/qemu-minimal.config")"
KERNEL_RELEASE="6.12.117\${LOCALVERSION:--sadim}"
cat > "$ISODIR/sadim/VERSION" <<EOF
Sadim OS v0.2-daily
Build: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Kernel: \${KERNEL_RELEASE}
Target: Acer Aspire E5-576G (i5-7200U, 4GB RAM)
Boot: Legacy BIOS / hybrid USB
Mode: Live only; rootfs SquashFS + volatile tmpfs overlay
EOF

cat > "$ISODIR/isolinux/isolinux.cfg" <<'EOF'
DEFAULT sadim
PROMPT 1
TIMEOUT 50
LABEL sadim
  MENU LABEL Sadim OS — Live
  KERNEL /boot/vmlinuz-sadim
  APPEND initrd=/boot/initramfs-sadim.img console=tty0 console=ttyS0,115200 panic=-1 SADIM_CI=0
LABEL safe
  MENU LABEL Safe mode (ACPI/APIC disabled)
  KERNEL /boot/vmlinuz-sadim
  APPEND initrd=/boot/initramfs-sadim.img console=tty0 console=ttyS0,115200 panic=-1 noacpi nolapic SADIM_CI=0
EOF

ISOLINUX_DIR="/usr/lib/ISOLINUX"
SYSLINUX_MODULES="/usr/lib/syslinux/modules/bios"
[ -f "$ISOLINUX_DIR/isolinux.bin" ] || { echo "FAIL: isolinux.bin missing"; exit 1; }
[ -f "$ISOLINUX_DIR/isohdpfx.bin" ] || { echo "FAIL: isohdpfx.bin missing"; exit 1; }
[ -f "$SYSLINUX_MODULES/ldlinux.c32" ] || { echo "FAIL: ldlinux.c32 missing"; exit 1; }
cp "$ISOLINUX_DIR/isolinux.bin" "$ISODIR/isolinux/"
cp "$SYSLINUX_MODULES/ldlinux.c32" "$ISODIR/isolinux/"

xorriso -as mkisofs \
  -o "$OUT/sadim.iso" \
  -isohybrid-mbr "$ISOLINUX_DIR/isohdpfx.bin" \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -V "$ISO_LABEL" \
  -A "Sadim OS v0.2-daily" \
  -P "Sadim OS Project" \
  "$ISODIR"

ISO_SIZE=$(stat -c%s "$OUT/sadim.iso")
test "$ISO_SIZE" -gt 1048576 || { echo "FAIL: ISO unexpectedly small ($ISO_SIZE bytes)"; exit 1; }
file "$OUT/sadim.iso"
echo "[sadim] OK: $OUT/sadim.iso ($ISO_SIZE bytes) — Legacy BIOS hybrid Live USB"
