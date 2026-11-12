#!/usr/bin/env bash
# Sadim OS — بناء Live ISO v0.2-daily قابل للإقلاع BIOS (CD + USB هجين)
# مسار الإقلاع: isolinux → kernel + initramfs v0.3 → live/rootfs.squashfs (iso9660+loop)
#         → overlayfs → switch_root → جذر Buildroot حي + خدمات + DHCP + تحسينات SMR
# لا يلمس أي قرص داخلي — مجرد بناء صورة للاستخدام اليومي من USB 2.0
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
ISODIR="$OUT/iso-staging"
ISO_LABEL="SADIM_02_DAILY"

[ -f "$OUT/bzImage" ] || { echo "FAIL: bzImage missing"; exit 1; }
[ -f "$OUT/initramfs.cpio.gz" ] || { echo "FAIL: initramfs missing"; exit 1; }
[ -f "$OUT/rootfs.squashfs" ] || { echo "FAIL: rootfs.squashfs missing (run sadim/rootfs/build.sh first)"; exit 1; }

rm -rf "$ISODIR"
mkdir -p "$ISODIR/boot" "$ISODIR/isolinux" "$ISODIR/live" "$ISODIR/sadim"

cp "$OUT/bzImage" "$ISODIR/boot/vmlinuz-sadim"
cp "$OUT/initramfs.cpio.gz" "$ISODIR/boot/initramfs-sadim.img"
cp "$OUT/rootfs.squashfs" "$ISODIR/live/rootfs.squashfs"

# ملف إصدار système
cat > "$ISODIR/sadim/VERSION" <<'EOF'
Sadim OS 0.2-daily
Build: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Kernel: $(uname -r 2>/dev/null || echo 6.12.117-sadim-phase4)
Target: Acer E5-576G (i5-7200U, 4GB RAM, SMR HDD)
USB: USB 2.0 متوافق
EOF

# إعداد isolinux.cfg مع خيارات إقلاع متعددة
cat > "$ISODIR/isolinux/isolinux.cfg" <<'EOF'
DEFAULT sadim
PROMPT 1
TIMEOUT 50
LABEL sadim
  KERNEL /boot/vmlinuz-sadim
  APPEND initrd=/boot/initramfs-sadim.img console=tty0 console=ttyS0,115200 panic=-1 SADIM_CI=0
LABEL safe
  KERNEL /boot/vmlinuz-sadim
  APPEND initrd=/boot/initramfs-sadim.img console=tty0 console=ttyS0,115200 panic=-1 noacpi nolapic SADIM_CI=0
LABEL memtest
  KERNEL /boot/vmlinuz-sadim
  APPEND initrd=/boot/initramfs-sadim.img console=tty0 console=ttyS0,115200 panic=-1 memtest SADIM_CI=0
EOF

# ملفات محمل الإقلاع من حزم CI الرسمية
ISOLINUX_DIR="/usr/lib/ISOLINUX"
SYSLINUX_MODULES="/usr/lib/syslinux/modules/bios"
[ -f "$ISOLINUX_DIR/isolinux.bin" ] || { echo "FAIL: isolinux.bin missing (apt install isolinux)"; exit 1; }
[ -f "$ISOLINUX_DIR/isohdpfx.bin" ] || { echo "FAIL: isohdpfx.bin missing (hybrid MBR)"; exit 1; }
[ -f "$SYSLINUX_MODULES/ldlinux.c32" ] || { echo "FAIL: ldlinux.c32 missing (apt install syslinux-common)"; exit 1; }
cp "$ISOLINUX_DIR/isolinux.bin" "$ISODIR/isolinux/"
cp "$SYSLINUX_MODULES/ldlinux.c32" "$ISODIR/isolinux/"

# بناء صورة ISO هجينة (تقلع من CD و USB 2.0)
xorriso -as mkisofs \
  -o "$OUT/sadim.iso" \
  -isohybrid-mbr "$ISOLINUX_DIR/isohdpfx.bin" \
  -c isolinux/boot.cat \
  -b isolinux/isolinux.bin \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -V "$ISO_LABEL" \
  -A "Sadim OS 0.2-daily" \
  -P "Sadim OS Project" \
  "$ISODIR"

# جعل الصورة قابلة للإقلاع من USB (isohybrid)
if command -v isohybrid >/dev/null 2>&1; then
  isohybrid "$OUT/sadim.iso" 2>/dev/null || true
fi

ISO_SIZE=$(stat -c%s "$OUT/sadim.iso" 2>/dev/null || echo 0)
echo "[sadim] OK: $OUT/sadim.iso (${ISO_SIZE} bytes) — BIOS hybrid (CD + USB 2.0) — الإصدار v0.2-daily"
echo "[sadim] اكتب الصورة على فلاشة USB 2.0 باستخدام: dd if=sadim.iso of=/dev/sdX bs=4M status=progress"
