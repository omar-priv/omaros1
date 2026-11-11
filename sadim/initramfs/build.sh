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
  # applet tc لا يترجم ضد ترويسات نواة حديثة (تُزيل بنى CBQ) وهو غير مطلوب في سديم — تعطيل صريح
  # ملاحظة: تعديل رموز موجودة في .config مباشرة كافٍ — لا حاجة لإعادة توليد
  # (busybox kconfig لا يملك olddefconfig، وyes|oldconfig يفشل مع pipefail على broken pipe)
  sed -i 's/^CONFIG_TC=y/# CONFIG_TC is not set/' .config
  make -j"$(nproc)" >/dev/null
  cd ..
fi

rm -rf staging
mkdir -p staging/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,etc,root,tmp,home/sadim,var/log,var/run}
make -C "$BVB" CONFIG_PREFIX="$PWD/staging" install >/dev/null

# init خاص بـ Sadim OS (المصدر الحقيقي للسلوك)
cp "$ROOT/initramfs/init" staging/init
chmod 755 staging/init

# طبقة النظام: /etc (هوية سديم، مستخدمون، inittab) — ملفات حقيقية قابلة للمراجعة
cp -a "$ROOT/initramfs/rootfs/." staging/
chmod 755 staging/etc/rcS staging/bin/autologin
chmod 644 staging/etc/passwd staging/etc/group staging/etc/inittab \
          staging/etc/profile staging/etc/os-release staging/etc/issue \
          staging/etc/motd staging/etc/hostname

cd staging
find . | cpio -o -H newc --owner root:root --quiet | gzip > "$OUT/initramfs.cpio.gz"
cd ..
echo "[sadim] OK: $OUT/initramfs.cpio.gz ($(stat -c%s "$OUT/initramfs.cpio.gz") bytes)"
