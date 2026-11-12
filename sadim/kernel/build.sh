#!/usr/bin/env bash
# Build the Linux kernel from source and verify all required Live/hardware options.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
DL="$OUT/dl"
SRCROOT="$OUT/src"
VERSION="$(sed -n 's/^KERNEL_VERSION=//p' "$ROOT/kernel/version.mk" | tr -d '[:space:]')"

[ -n "$VERSION" ] || { echo "ERROR: KERNEL_VERSION missing in kernel/version.mk"; exit 1; }
mkdir -p "$DL" "$SRCROOT" "$OUT"
KERNEL_LOG="$OUT/kernel-build.log"
: > "$KERNEL_LOG"
exec > >(tee -a "$KERNEL_LOG") 2>&1
cd "$DL"
TARBALL="linux-$VERSION.tar.xz"

if [ ! -s "$TARBALL" ]; then
  echo "[sadim] downloading $TARBALL"
  wget -q --show-progress "https://cdn.kernel.org/pub/linux/kernel/v6.x/$TARBALL"
fi
echo "[sadim] verifying SHA256 against kernel.org sha256sums.asc"
wget -q -O sha256sums.asc "https://cdn.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc"
grep " $TARBALL" sha256sums.asc | sha256sum -c -
rm -f sha256sums.asc

SRC="$SRCROOT/linux-$VERSION"
if [ ! -s "$SRC/arch/x86/boot/bzImage" ]; then
  rm -rf "$SRC"
  mkdir -p "$SRCROOT"
  tar xf "$TARBALL" -C "$SRCROOT"
  cd "$SRC"
  echo "[sadim] tinyconfig + Sadim hardware/Live fragment"
  make tinyconfig
  ./scripts/kconfig/merge_config.sh -m .config "$ROOT/kernel/fragments/qemu-minimal.config"
  # Make the dependency chain explicit: USB mass storage requires SCSI, which
  # requires the block layer. Keep these built in for USB Live boot.
  ./scripts/config --enable BLOCK --enable SCSI --enable USB_SUPPORT --enable USB --enable USB_STORAGE
  make olddefconfig

  echo "[sadim] effective USB storage dependency chain:"
  for symbol in CONFIG_BLOCK CONFIG_SCSI CONFIG_USB_SUPPORT CONFIG_USB CONFIG_USB_STORAGE; do
    grep -E "^\${symbol}=|^# \${symbol} is not set$" .config || echo "$symbol missing or unset"
  done

  # Kconfig silently drops unknown symbols or options with unmet dependencies.
  # Fail here instead of producing a kernel missing essential Live boot support.
  required=(
    CONFIG_BLK_DEV_INITRD CONFIG_BLOCK CONFIG_SCSI CONFIG_USB_SUPPORT CONFIG_USB CONFIG_USB_STORAGE CONFIG_BLK_DEV_SD
    CONFIG_SQUASHFS CONFIG_ISO9660_FS CONFIG_BLK_DEV_LOOP CONFIG_OVERLAY_FS
    CONFIG_DRM_I915 CONFIG_ATH10K_PCI CONFIG_R8169 CONFIG_SND_HDA_INTEL
    CONFIG_ZSMALLOC CONFIG_ZRAM CONFIG_DEVTMPFS CONFIG_DEVTMPFS_MOUNT
  )
  for symbol in "${required[@]}"; do
    grep -qx "${symbol}=y" .config || {
      echo "ERROR: required kernel option missing after olddefconfig: ${symbol}"
      exit 1
    }
  done
  echo "[sadim] required kernel options verified"
  echo "[sadim] building bzImage ($(nproc) jobs)"
  make -j"$(nproc)" bzImage
fi

cp "$SRC/arch/x86/boot/bzImage" "$OUT/bzImage"
test -s "$OUT/bzImage"
echo "[sadim] OK: $OUT/bzImage ($(stat -c%s "$OUT/bzImage") bytes)"
