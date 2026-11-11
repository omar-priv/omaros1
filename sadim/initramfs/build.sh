#!/usr/bin/env bash
# Sadim OS — بناء initramfs: BusyBox ثابت + init خاص بالمشروع (المرحلة 2)
# المخرجات: sadim/output/initramfs.cpio.gz
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
mkdir -p "$OUT"
cd "$OUT"

BVB="busybox-1.36.1"
if [ ! -x "$BVB/busybox" ]; then
  if [ ! -d "$BVB" ]; then
    echo "[sadim] downloading $BVB"
    wget -q --show-progress "https://busybox.net/downloads/$BVB.tar.bz2"
    tar xf "$BVB.tar.bz2"
  fi
  cd "$BVB"
  echo "[sadim] busybox defconfig + STATIC"
  make defconfig >/dev/null
  sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
  make -j"$(nproc)" >/dev/null
  cd ..
fi

rm -rf staging
mkdir -p staging/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,etc,root,tmp}
make -C "$BVB" CONFIG_PREFIX="$PWD/staging" install >/dev/null

# init خاص بـ Sadim OS (المصدر الحقيقي للسلوك)
cp "$ROOT/initramfs/init" staging/init
chmod 755 staging/init

cd staging
find . | cpio -o -H newc --quiet | gzip > "$OUT/initramfs.cpio.gz"
cd ..
echo "[sadim] OK: $OUT/initramfs.cpio.gz ($(stat -c%s "$OUT/initramfs.cpio.gz") bytes)"
