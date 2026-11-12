#!/usr/bin/env bash
# Sadim OS — بوابة المراحل 3-12: إقلاع الجذر الحي كاملاً في QEMU
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
LOG="$OUT/rootfs-boot-log.txt"

[ -f "$OUT/bzImage" ]            || { echo "FAIL: bzImage missing"; exit 1; }
[ -f "$OUT/initramfs.cpio.gz" ]  || { echo "FAIL: initramfs missing"; exit 1; }
[ -f "$OUT/rootfs.squashfs" ]    || { echo "FAIL: rootfs.squashfs missing"; exit 1; }

: > "$LOG"
RUNS=3
ok=0
echo "[sadim] rootfs boot gate v0.5: $RUNS consecutive runs required (12 markers ×3)"
for i in $(seq 1 $RUNS); do
  rlog="$OUT/rootfs-boot-log-run$i.txt"
  : > "$rlog"
  echo "[sadim] rootfs boot test run $i/$RUNS: QEMU (TCG, virtio rootfs + virtio-net)"
  timeout 150 qemu-system-x86_64 \
    -m 320M -nographic -no-reboot \
    -kernel "$OUT/bzImage" \
    -initrd "$OUT/initramfs.cpio.gz" \
    -drive file="$OUT/rootfs.squashfs",if=virtio,format=raw,readonly=on \
    -device virtio-net-pci,netdev=n0 -netdev user,id=n0 \
    -append "console=ttyS0 rdinit=/init panic=-1 loglevel=7 SADIM_CI=1" \
    2>&1 | tee -a "$rlog"
  status=${PIPESTATUS[0]}
  echo "[sadim] run $i: qemu exit code $status"
  if grep -q "SADIM-BOOT-OK"   "$rlog" \
     && grep -q "SADIM-LIVE-OK"   "$rlog" \
     && grep -q "SADIM-ROOTFS-OK" "$rlog" \
     && grep -q "SADIM-NET-OK"    "$rlog" \
     && grep -q "SADIM-HW-OK"     "$rlog" \
     && grep -q "SADIM-PERF-OK"   "$rlog" \
     && grep -q "SADIM-SHELL-OK"  "$rlog" \
     && grep -q "SADIM-WIN10-OK"  "$rlog" \
     && grep -q "SADIM-ADMIN-OK"  "$rlog" \
     && grep -q "SADIM-BRAVE-OK"  "$rlog" \
     && grep -q "SADIM-WINE-OK"   "$rlog"; then
    ok=$((ok+1))
    cp "$rlog" "$LOG"
  else
    echo "[sadim] run $i FAILED — one or more markers missing"
    for m in SADIM-BOOT-OK SADIM-LIVE-OK SADIM-ROOTFS-OK SADIM-NET-OK SADIM-HW-OK SADIM-PERF-OK SADIM-SHELL-OK SADIM-WIN10-OK SADIM-ADMIN-OK SADIM-BRAVE-OK SADIM-WINE-OK; do
      grep -q "$m" "$rlog" && echo "  marker $m: PRESENT" || echo "  marker $m: MISSING"
    done
    cp "$rlog" "$LOG"
  fi
done

if [ "$ok" -eq "$RUNS" ]; then
  echo "=============================================================="
  echo "  ROOTFS BOOT TEST PASSED — all 11 markers x3 (v0.5)"
  echo "=============================================================="
  exit 0
else
  echo "=============================================================="
  echo "  ROOTFS BOOT TEST FAILED — $ok/$RUNS runs ok"
  echo "=============================================================="
  exit 1
fi
