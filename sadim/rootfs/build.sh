#!/usr/bin/env bash
# Sadim OS — المرحلة 3: بناء الجذر الحي عبر Buildroot LTS 2025.02.19
# المخرجات: sadim/output/rootfs.squashfs (يُقلع عبر squashfs+overlayfs من init v0.3)
# المصدر: المرآة الرسمية github.com/buildroot/buildroot وسم 2025.02.19 مثبت البصمة
# (buildroot.org TLS شهادتها منتهية حالياً — موثقة ENV-4 في known-issues)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
mkdir -p "$OUT/dl-rootfs" "$OUT/ccache" "$OUT/brconf"
cd "$OUT"

BRV="buildroot-2025.02.19"
# بصمة التربل من المرآة الرسمية (وسم 2025.02.19 — tag object 26cf1107…)
BR_SHA256="0fc9583d1b019b42c0cf3ea1dc64899a2247ab9adbce47f47ac5d4cb13ce0c98"
BR_URL="https://github.com/buildroot/buildroot/archive/refs/tags/2025.02.19.tar.gz"

# طبقة سديم فوق الجذر: نفس ملفات /etc المنفذة في initramfs (مصدر واحد للحقيقة)
OVERLAY="$ROOT/initramfs/rootfs"
test -d "$OVERLAY/etc" || { echo "FATAL: overlay layer missing: $OVERLAY"; exit 1; }

# توليد defconfig سديم من القالب (تثبيت مسار الطبقة الفعلي)
sed "s|@OVERLAY@|$OVERLAY|g" "$ROOT/rootfs/sadim-rootfs.config" > "$OUT/brconf/sadim_defconfig"

if [ ! -d "$BRV" ]; then
  echo "[sadim] downloading $BRV (official mirror tag)"
  wget -q "$BR_URL"
  echo "$BR_SHA256  $BRV.tar.gz" | sha256sum -c -
  tar xf "$BRV.tar.gz"
fi

cd "$BRV"
echo "[sadim] buildroot defconfig (sadim-rootfs.config)"
make BR2_DEFCONFIG="$OUT/brconf/sadim_defconfig" \
     BR2_DL_DIR="$OUT/dl-rootfs" \
     BR2_CCACHE_DIR="$OUT/ccache" \
     O="$OUT/buildroot-build" defconfig

echo "[sadim] buildroot make (musl + busybox + kmod → squashfs)"
make BR2_DL_DIR="$OUT/dl-rootfs" \
     BR2_CCACHE_DIR="$OUT/ccache" \
     O="$OUT/buildroot-build" -j"$(nproc)"

cp "$OUT/buildroot-build/images/rootfs.squashfs" "$OUT/rootfs.squashfs"
echo "[sadim] OK: $OUT/rootfs.squashfs ($(stat -c%s "$OUT/rootfs.squashfs") bytes)"
