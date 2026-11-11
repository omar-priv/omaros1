#!/usr/bin/env bash
# Sadim OS — بناء Live ISO v0.3 قابل للإقلاع BIOS (CD + USB هجين)
# مسار الإقلاع: isolinux → kernel + initramfs v0.3 → live/rootfs.squashfs (iso9660+loop)
#         → overlayfs → switch_root → جذر Buildroot حي + خدمات + DHCP حقيقي
# لا يلمس أي قرص داخلي — مجرد بناء صورة.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
ISODIR="$OUT/iso-staging"

[ -f "$OUT/bzImage" ] || { echo "FAIL: bzImage missing"; exit 1; }
[ -f "$OUT/initramfs.cpio.gz" ] || { echo "FAIL: initramfs missing"; exit 1; }
# ISO v0.2: الجذر الحي (Buildroot) جزء إلزامي من الصورة — بلا rootfs لا بناء
[ -f "$OUT/rootfs.squashfs" ] || { echo "FAIL: rootfs.squashfs missing (run sadim/rootfs/build.sh first)"; exit 1; }

rm -rf "$ISODIR"
mkdir -p "$ISODIR/boot" "$ISODIR/isolinux" "$ISODIR/live"

cp "$OUT/bzImage" "$ISODIR/boot/vmlinuz-sadim"
cp "$OUT/initramfs.cpio.gz" "$ISODIR/boot/initramfs-sadim.img"
cp "$OUT/rootfs.squashfs" "$ISODIR/live/rootfs.squashfs"

cat > "$ISODIR/isolinux/isolinux.cfg" <<'EOF'
DEFAULT sadim
PROMPT 0
TIMEOUT 30
LABEL sadim
  KERNEL /boot/vmlinuz-sadim
  APPEND initrd=/boot/initramfs-sadim.img console=tty0 console=ttyS0,115200 panic=-1
EOF

# ملفات محمل الإقلاع من حزم CI الرسمية
ISOLINUX_DIR="/usr/lib/ISOLINUX"
SYSLINUX_MODULES="/usr/lib/syslinux/modules/bios"
[ -f "$ISOLINUX_DIR/isolinux.bin" ] || { echo "FAIL: isolinux.bin missing (apt install isolinux)"; exit 1; }
[ -f "$ISOLINUX_DIR/isohdpfx.bin" ] || { echo "FAIL: isohdpfx.bin missing (hybrid MBR)"; exit 1; }
[ -f "$SYSLINUX_MODULES/ldlinux.c32" ] || { echo "FAIL: ldlinux.c32 missing (apt install syslinux-common)"; exit 1; }
cp "$ISOLINUX_DIR/isolinux.bin" "$ISODIR/isolinux/"
cp "$SYSLINUX_MODULES/ldlinux.c32" "$ISODIR/isolinux/"

xorriso -as mkisofs \
  -o "$OUT/sadim.iso" \
  -isohybrid-mbr "$ISOLINUX_DIR/isohdpfx.bin" \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -V SADIM_LIVE \
  "$ISODIR"

echo "[sadim] OK: $OUT/sadim.iso ($(stat -c%s "$OUT/sadim.iso") bytes) — BIOS hybrid (CD + USB)"
