#!/usr/bin/env bash
# Build static BusyBox initramfs plus Sadim init, service overlay and Wi-Fi firmware.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
mkdir -p "$OUT"
cd "$OUT"

BVB="busybox-1.36.1"
BB_SHA256="b8cc24c9574d809e7279c3be349795c5d5ceb6fdf19ca709f80cde50e47de314"
if [ ! -x "$BVB/busybox" ]; then
  if [ ! -d "$BVB" ]; then
    echo "[sadim] downloading $BVB"
    wget -q --show-progress "https://busybox.net/downloads/$BVB.tar.bz2"
    echo "$BB_SHA256  $BVB.tar.bz2" | sha256sum -c -
    tar xf "$BVB.tar.bz2"
  fi
  cd "$BVB"
  echo "[sadim] BusyBox defconfig + static build"
  make defconfig >/dev/null
  sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
  # BusyBox tc does not build against the modern kernel UAPI and is not used.
  sed -i 's/^CONFIG_TC=y/# CONFIG_TC is not set/' .config
  make -j"$(nproc)" >/dev/null
  cd ..
fi

# Fail early if required early-boot applets are absent.
for applet in mount umount switch_root mdev mkswap swapon swapoff; do
  "$BVB/busybox" --list | grep -qx "$applet" || {
    echo "ERROR: required BusyBox applet missing: $applet"
    exit 1
  }
done

# The ath10k driver is built into the kernel, so its firmware must be present
# in initramfs before the full SquashFS root can be mounted.
FW_SOURCE="$OUT/buildroot-build/target/lib/firmware/ath10k/QCA9377"
test -s "$FW_SOURCE/hw1.0/firmware-5.bin" || {
  echo "ERROR: Buildroot QCA9377 firmware-5.bin missing; build rootfs before initramfs"
  exit 1
}

rm -rf staging
mkdir -p staging/{bin,sbin,usr/bin,usr/sbin,proc,sys,dev,etc,root,tmp,home/sadim,var/log,var/run,run,lib/firmware/ath10k}
make -C "$BVB" CONFIG_PREFIX="$PWD/staging" install >/dev/null
mkdir -p staging/lib/firmware/ath10k/QCA9377
cp -a "$FW_SOURCE/." staging/lib/firmware/ath10k/QCA9377/

cp "$ROOT/initramfs/init" staging/init
chmod 755 staging/init
cp -a "$ROOT/initramfs/rootfs/." staging/
chmod 755 staging/etc/rcS staging/bin/autologin
# rcS executes these files directly; set and preserve executable mode.
if [ -d staging/etc/init.d ]; then
  find staging/etc/init.d -maxdepth 1 -type f -name 'S*' -exec chmod 755 {} +
fi
chmod 644 staging/etc/passwd staging/etc/group staging/etc/inittab \
          staging/etc/profile staging/etc/os-release staging/etc/issue \
          staging/etc/motd staging/etc/hostname

test -s staging/lib/firmware/ath10k/QCA9377/hw1.0/firmware-5.bin
cd staging
find . | cpio -o -H newc --owner root:root --quiet | gzip > "$OUT/initramfs.cpio.gz"
cd ..
echo "[sadim] OK: $OUT/initramfs.cpio.gz ($(stat -c%s "$OUT/initramfs.cpio.gz") bytes)"
