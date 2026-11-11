#!/usr/bin/env bash
# Sadim OS — اختبار إقلاع ISO v0.3 عبر QEMU بمسار BIOS الحقيقي
# (SeaBIOS → isolinux → kernel → init v0.3 → iso9660+loop → overlayfs → خدمات → DHCP)
# 3 إقلاعات متتالية مطلوبة (ضد العشوائية). في وضع ISO النظام يبقى حياً (لا reboot) —
# نجاح كل تشغيل = العلامات الأربع داخل المهلة دون Kernel panic.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
LOG="$OUT/iso-boot-log.txt"

[ -f "$OUT/sadim.iso" ] || { echo "FAIL: sadim.iso missing"; exit 1; }

: > "$LOG"
RUNS=3
ok=0
echo "[sadim] ISO boot gate: $RUNS consecutive runs required (v0.2: full live system via real boot path)"
for i in $(seq 1 $RUNS); do
  rlog="$OUT/iso-boot-log-run$i.txt"
  : > "$rlog"
  echo "[sadim] ISO boot run $i/$RUNS: SeaBIOS + isolinux + kernel + live rootfs (TCG)"
  timeout 300 qemu-system-x86_64 \
    -m 512M -nographic -no-reboot \
    -cdrom "$OUT/sadim.iso" -boot d \
    -device virtio-net-pci,netdev=n0 -netdev user,id=n0 \
    2>&1 | tee -a "$rlog"
  status=${PIPESTATUS[0]}
  echo "[sadim] run $i: qemu exit code $status"
  if grep -q "SADIM-BOOT-OK"   "$rlog" \
     && grep -q "SADIM-LIVE-OK"   "$rlog" \
     && grep -q "SADIM-ROOTFS-OK" "$rlog" \
     && grep -q "SADIM-NET-OK"    "$rlog"; then
    ok=$((ok+1))
    cp "$rlog" "$LOG"
  else
    echo "[sadim] run $i FAILED — one or more markers missing"
    for m in SADIM-BOOT-OK SADIM-LIVE-OK SADIM-ROOTFS-OK SADIM-NET-OK; do
      grep -q "$m" "$rlog" && echo "  marker $m: PRESENT" || echo "  marker $m: MISSING"
    done
    echo "---- last 60 lines of run $i ISO boot log ----"
    tail -n 60 "$rlog"
    cp "$rlog" "$LOG"
  fi
done

if [ "$ok" -eq "$RUNS" ]; then
  echo "=================================================="
  echo "  ISO BOOT TEST PASSED — all 4 markers x3 (real path)"
  echo "=================================================="
  exit 0
else
  echo "=================================================="
  echo "  ISO BOOT TEST FAILED ($ok/$RUNS runs reached all markers)"
  echo "=================================================="
  exit 1
fi
