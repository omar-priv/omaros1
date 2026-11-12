#!/usr/bin/env bash
# Buildroot Live rootfs build with Kconfig retention and runtime-file checks.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
mkdir -p "$OUT/dl-rootfs" "$OUT/ccache" "$OUT/brconf" "$OUT/buildroot-build"
BUILD_LOG="$OUT/buildroot-build/build.log"
: > "$BUILD_LOG"
cd "$OUT"
BRV="buildroot-2025.02.19"
BR_SHA256="0fc9583d1b019b42c0cf3ea1dc64899a2247ab9adbce47f47ac5d4cb13ce0c98"
BR_URL="https://github.com/buildroot/buildroot/archive/refs/tags/2025.02.19.tar.gz"
OVERLAY="$ROOT/initramfs/rootfs"
test -d "$OVERLAY/etc" || { echo "FATAL: overlay layer missing: $OVERLAY"; exit 1; }

sed "s|@OVERLAY@|$OVERLAY|g" "$ROOT/rootfs/sadim-rootfs.config" > "$OUT/brconf/sadim_defconfig"
if [ ! -d "$BRV" ]; then
  echo "[sadim] downloading $BRV from the official Buildroot mirror"
  wget -q -O "$BRV.tar.gz" "$BR_URL"
  echo "$BR_SHA256  $BRV.tar.gz" | sha256sum -c -
  tar xf "$BRV.tar.gz"
fi

cd "$BRV"
echo "[sadim] generating Buildroot configuration"
make BR2_DEFCONFIG="$OUT/brconf/sadim_defconfig" \
     BR2_DL_DIR="$OUT/dl-rootfs" \
     BR2_CCACHE_DIR="$OUT/ccache" \
     O="$OUT/buildroot-build" defconfig 2>&1 | tee -a "$BUILD_LOG"

# Kconfig silently drops unknown symbols and symbols whose dependencies fail.
python3 - "$OUT/brconf/sadim_defconfig" "$OUT/buildroot-build/.config" <<'PY'
import re
import sys
requested_path, effective_path = sys.argv[1:3]
requested, effective = set(), set()
for path, target in ((requested_path, requested), (effective_path, effective)):
    with open(path, encoding="utf-8") as stream:
        for line in stream:
            match = re.match(r"^(BR2_[A-Z0-9_]+)=y$", line.strip())
            if match:
                target.add(match.group(1))
missing = sorted(requested - effective)
if missing:
    print("ERROR: Buildroot dropped requested symbols:")
    print("\n".join("  - " + item for item in missing))
    sys.exit(1)
required = {
    "BR2_PACKAGE_WESTON",
    "BR2_PACKAGE_WESTON_SHELL_DESKTOP",
    "BR2_PACKAGE_EUDEV",
    "BR2_PACKAGE_SEATD_DAEMON",
    "BR2_PACKAGE_LINUX_FIRMWARE_ATHEROS_10K_QCA9377",
    "BR2_PACKAGE_WPA_SUPPLICANT_NL80211",
    "BR2_PACKAGE_IPROUTE2",
    "BR2_TARGET_ROOTFS_SQUASHFS",
}
missing_required = sorted(required - effective)
if missing_required:
    print("ERROR: required runtime features are not enabled:")
    print("\n".join("  - " + item for item in missing_required))
    sys.exit(1)
print("Buildroot config validated: %d requested symbols retained." % len(requested))
PY

echo "[sadim] building complete root filesystem"
make BR2_DL_DIR="$OUT/dl-rootfs" \
     BR2_CCACHE_DIR="$OUT/ccache" \
     O="$OUT/buildroot-build" -j"$(nproc)" 2>&1 | tee -a "$BUILD_LOG"

TARGET="$OUT/buildroot-build/target"
test -x "$TARGET/usr/bin/weston" || { echo "ERROR: Weston binary missing"; exit 1; }
test -x "$TARGET/usr/bin/seatd" || { echo "ERROR: seatd daemon missing; enable BR2_PACKAGE_SEATD_DAEMON"; exit 1; }
test -x "$TARGET/etc/init.d/S10udev" || { echo "ERROR: Buildroot S10udev service missing"; exit 1; }
test -x "$TARGET/etc/init.d/S70seatd" || { echo "ERROR: Buildroot S70seatd service missing"; exit 1; }
test -x "$TARGET/etc/init.d/S25-network" || { echo "ERROR: ordered S25-network service missing"; exit 1; }
test -x "$TARGET/etc/init.d/S75-weston" || { echo "ERROR: ordered Weston S75 service missing"; exit 1; }
grep -Eq '^video:[^:]*:28:.*sadim' "$TARGET/etc/group" || {
  echo "ERROR: video group (GID 28) or Sadim membership missing"; exit 1;
}
test -x "$TARGET/bin/busybox" || { echo "ERROR: Buildroot BusyBox binary missing"; exit 1; }
for applet in mkswap swapon swapoff; do
  "$TARGET/bin/busybox" --list | grep -qx "$applet" || {
    echo "ERROR: Buildroot BusyBox applet missing: $applet"
    exit 1
  }
done
test -s "$TARGET/lib/firmware/ath10k/QCA9377/hw1.0/firmware-5.bin" || {
  echo "ERROR: QCA9377 firmware-5.bin missing from target rootfs"; exit 1;
}
if find "$TARGET/etc/init.d" -maxdepth 1 -type f -name 'S*' ! -perm -u+x -print -quit 2>/dev/null | grep -q .; then
  echo "ERROR: Buildroot overlay contains non-executable init services"
  exit 1
fi
test -s "$OUT/buildroot-build/images/rootfs.squashfs" || {
  echo "ERROR: Buildroot did not produce rootfs.squashfs"; exit 1;
}
cp "$OUT/buildroot-build/images/rootfs.squashfs" "$OUT/rootfs.squashfs"
unsquashfs -s "$OUT/rootfs.squashfs"
echo "[sadim] OK: $OUT/rootfs.squashfs ($(stat -c%s "$OUT/rootfs.squashfs") bytes)"
