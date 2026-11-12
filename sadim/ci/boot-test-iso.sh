#!/usr/bin/env bash
# Boot the actual hybrid ISO through SeaBIOS and ISOLINUX.
# Only assert markers emitted by implemented startup services.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
ISO="$OUT/sadim.iso"
LOG="$OUT/iso-boot-log.txt"
MARKERS=(SADIM-BOOT-OK SADIM-LIVE-OK SADIM-ROOTFS-OK SADIM-NET-OK SADIM-GUI-OK)
[ -s "$ISO" ] || { echo "FAIL: sadim.iso missing"; exit 1; }
: > "$LOG"
RUNS=3
ok=0
echo "[sadim] ISO boot gate: $RUNS consecutive SeaBIOS/ISOLINUX boots"
for i in $(seq 1 "$RUNS"); do
  rlog="$OUT/iso-boot-log-run$i.txt"
  : > "$rlog"
  timeout 90 qemu-system-x86_64 \
    -m 1024M -nographic -no-reboot -vga virtio \
    -cdrom "$ISO" -boot d \
    -device virtio-net-pci,netdev=n0 -netdev user,id=n0 \
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
if [ "$ok" -eq "$RUNS" ]; then echo "[sadim] ISO BOOT TEST PASSED ($ok/$RUNS)"; exit 0; fi
echo "[sadim] ISO BOOT TEST FAILED ($ok/$RUNS)"
exit 1
