#!/usr/bin/env bash
# QEMU Live rootfs smoke test; this does not certify real Acer hardware.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
LOG="$OUT/rootfs-boot-log.txt"
MARKERS=(SADIM-BOOT-OK SADIM-LIVE-OK SADIM-ROOTFS-OK SADIM-NET-OK SADIM-GUI-OK)
for f in "$OUT/bzImage" "$OUT/initramfs.cpio.gz" "$OUT/rootfs.squashfs"; do
  [ -s "$f" ] || { echo "FAIL: missing build output: $f"; exit 1; }
done
: > "$LOG"
RUNS=3
ok=0
echo "[sadim] rootfs QEMU gate: $RUNS runs; markers: ${MARKERS[*]}"
for i in $(seq 1 "$RUNS"); do
  rlog="$OUT/rootfs-boot-log-run$i.txt"
  : > "$rlog"
  timeout 120 qemu-system-x86_64 \
    -m 1024M -nographic -no-reboot -vga virtio \
    -kernel "$OUT/bzImage" -initrd "$OUT/initramfs.cpio.gz" \
    -drive file="$OUT/rootfs.squashfs",if=virtio,format=raw,readonly=on \
    -device virtio-net-pci,netdev=n0 -netdev user,id=n0 \
    -append "console=ttyS0 rdinit=/init panic=-1 loglevel=7 SADIM_CI=1" \
    2>&1 | tee "$rlog"
  status=${PIPESTATUS[0]}
  echo "[sadim] QEMU exit code: $status"
  missing=()
  for marker in "${MARKERS[@]}"; do
    grep -q "$marker" "$rlog" || missing+=("$marker")
  done
  if { [ "$status" -eq 0 ] || [ "$status" -eq 124 ]; } && [ "${#missing[@]}" -eq 0 ]; then
    ok=$((ok + 1))
    cp "$rlog" "$LOG"
    echo "[sadim] run $i passed"
  else
    echo "[sadim] run $i failed; exit=$status missing: ${missing[*]}"
    tail -n 60 "$rlog"
    cp "$rlog" "$LOG"
  fi
done
if [ "$ok" -eq "$RUNS" ]; then echo "[sadim] ROOTFS BOOT TEST PASSED ($ok/$RUNS)"; exit 0; fi
echo "[sadim] ROOTFS BOOT TEST FAILED ($ok/$RUNS)"
exit 1
