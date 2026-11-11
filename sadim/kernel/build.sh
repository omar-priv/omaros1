#!/usr/bin/env bash
# Sadim OS — بناء النواة من المصدر بتكوين المشروع (المرحلة 2)
# يعمل في CI (ubuntu) — لا يعتمد على Docker أو WSL.
# البنية: dl/ (التربل فقط — يُخبأ في CI) و src/ (شجرة البناء — لا تُخبأ).
# المخرجات: sadim/output/bzImage
# سلامة السلسلة: التربل يتحقق SHA256 مقابل sha256sums.asc من cdn.kernel.org نفسه.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"          # .../sadim
OUT="$ROOT/output"
DL="$OUT/dl"
SRCROOT="$OUT/src"
VERSION="$(sed -n 's/^KERNEL_VERSION=//p' "$ROOT/kernel/version.mk" | tr -d '[:space:]')"

[ -n "$VERSION" ] || { echo "ERROR: KERNEL_VERSION missing in kernel/version.mk"; exit 1; }

mkdir -p "$DL" "$SRCROOT"
cd "$DL"
TARBALL="linux-$VERSION.tar.xz"

echo "[sadim] downloading $TARBALL"
wget -q --show-progress "https://cdn.kernel.org/pub/linux/kernel/v6.x/$TARBALL"
echo "[sadim] verifying SHA256 against kernel.org sha256sums.asc"
wget -q "https://cdn.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc"
grep " $TARBALL" sha256sums.asc | sha256sum -c -
rm -f sha256sums.asc

SRC="$SRCROOT/linux-$VERSION"
if [ ! -f "$SRC/arch/x86/boot/bzImage" ]; then
  rm -rf "$SRC"
  mkdir -p "$SRCROOT"
  tar xf "$TARBALL" -C "$SRCROOT"
  cd "$SRC"
  echo "[sadim] tinyconfig + sadim fragment"
  make tinyconfig
  ./scripts/kconfig/merge_config.sh -m .config "$ROOT/kernel/fragments/qemu-minimal.config"
  make olddefconfig
  echo "[sadim] building bzImage ($(nproc) jobs)"
  make -j"$(nproc)" bzImage
fi

cp "$SRC/arch/x86/boot/bzImage" "$OUT/bzImage"
echo "[sadim] OK: $OUT/bzImage ($(stat -c%s "$OUT/bzImage") bytes)"
