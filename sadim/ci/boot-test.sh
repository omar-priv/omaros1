#!/usr/bin/env bash
# Sadim OS — اختبار الإقلاع في QEMU (المرحلة 2)
# بوابة النجاح: ظهور SADIM-BOOT-OK في اللوج قبل المهلة، دون Kernel Panic.
# QEMU يعمل بTCG (بلا KVM على الرنر) — إقلاع نواة مينية يستغرق ثوانٍ.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
LOG="$OUT/boot-log.txt"

[ -f "$OUT/bzImage" ] || { echo "FAIL: bzImage missing"; exit 1; }
[ -f "$OUT/initramfs.cpio.gz" ] || { echo "FAIL: initramfs missing"; exit 1; }

: > "$LOG"
RUNS=3
ok=0
echo "[sadim] boot gate: $RUNS consecutive runs required (anti-flakiness)"
for i in $(seq 1 $RUNS); do
  rlog="$OUT/boot-log-run$i.txt"
  : > "$rlog"
  echo "[sadim] boot test run $i/$RUNS: starting QEMU (TCG, serial console)"
  timeout 120 qemu-system-x86_64 \
    -m 256M -nographic -no-reboot \
    -kernel "$OUT/bzImage" \
    -initrd "$OUT/initramfs.cpio.gz" \
    -append "console=ttyS0 rdinit=/init panic=-1 loglevel=7 SADIM_CI=1" \
    2>&1 | tee -a "$rlog"
  status=${PIPESTATUS[0]}
  echo "[sadim] run $i: qemu exit code $status"
  if grep -q "SADIM-BOOT-OK" "$rlog"; then
    ok=$((ok+1))
    cp "$rlog" "$LOG"
  else
    echo "[sadim] run $i FAILED — marker not reached"
    echo "---- last 60 lines of run $i boot log ----"
    tail -n 60 "$rlog"
    cp "$rlog" "$LOG"
  fi
done

if [ "$ok" -eq "$RUNS" ]; then
  echo "=========================================="
  echo "  BOOT TEST PASSED — SADIM-BOOT-OK reached"
  echo "=========================================="
  exit 0
else
  echo "=========================================="
  echo "  BOOT TEST FAILED — marker not reached"
  echo "=========================================="
  echo "---- last 80 lines of boot log ----"
  tail -n 80 "$LOG"
  exit 1
fi
