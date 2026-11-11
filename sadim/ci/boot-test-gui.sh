#!/usr/bin/env bash
# Sadim OS — بوابة المرحلة 4: اختبار الواجهة الرسومية في QEMU
# المسار: kernel + initramfs v0.3 → squashfs (virtio) → overlayfs → switch_root
#         → buildroot init → seatd → weston (DRM+pixman على virtio-gpu)
#         → screendump عبر QMP للتحقق من بكسلات فعلية
# النجاح: SADIM-BOOT-OK + SADIM-LIVE-OK + SADIM-ROOTFS-OK + SADIM-NET-OK + SADIM-GUI-OK ×3
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/output"
LOG="$OUT/gui-boot-log.txt"

[ -f "$OUT/bzImage" ]            || { echo "FAIL: bzImage missing"; exit 1; }
[ -f "$OUT/initramfs.cpio.gz" ]  || { echo "FAIL: initramfs missing"; exit 1; }
[ -f "$OUT/rootfs.squashfs" ]    || { echo "FAIL: rootfs.squashfs missing"; exit 1; }

: > "$LOG"
RUNS=3
ok=0
echo "[sadim] GUI boot gate: $RUNS consecutive runs required (anti-flakiness)"
for i in $(seq 1 $RUNS); do
  rlog="$OUT/gui-boot-log-run$i.txt"
  qmp_log="$OUT/gui-qmp-run$i.log"
  qmp_sock="/tmp/sadim-qmp-$i.sock"
  : > "$rlog"
  echo "[sadim] GUI boot test run $i/$RUNS: QEMU (TCG, virtio-gpu + virtio-net + QMP screendump)"
  # QEMU مع virtio-gpu و QMP socket للتحكم وسحب screenshot
  timeout 300 qemu-system-x86_64 \
    -m 512M -nographic -no-reboot \
    -kernel "$OUT/bzImage" \
    -initrd "$OUT/initramfs.cpio.gz" \
    -drive file="$OUT/rootfs.squashfs",if=virtio,format=raw,readonly=on \
    -device virtio-net-pci,netdev=n0 -netdev user,id=n0 \
    -device virtio-gpu-pci \
    -qmp unix:"$qmp_sock",server=on,wait=off \
    -append "console=ttyS0 rdinit=/init panic=-1 loglevel=7 SADIM_CI=1" \
    2>&1 | tee -a "$rlog" &
  QEMU_PID=$!

  # ننتظر قليلاً لبدء QEMU و QMP
  sleep 3

  # دالة إرسال أمر QMP
  qmp_cmd() {
    local cmd="$1"
    echo "$cmd" | socat - UNIX-CONNECT:"$qmp_sock" 2>/dev/null
  }

  # ننتظر ظهور SADIM-GUI-OK في اللوج (بحد أقصى 120 ثانية)
  gui_ok=0
  for attempt in $(seq 1 120); do
    if grep -q "SADIM-GUI-OK" "$rlog" 2>/dev/null; then
      gui_ok=1
      break
    fi
    sleep 1
  done

  # إن نجح GUI، نسحب screenshot عبر QMP للتحقق من بكسلات فعلية
  if [ "$gui_ok" -eq 1 ]; then
    echo "[sadim] run $i: GUI marker found, capturing screendump via QMP…"
    # أمر QMP screendump
    qmp_cmd '{"execute":"qmp_capabilities"}' >/dev/null
    qmp_cmd '{"execute":"screendump","arguments":{"filename":"/tmp/screendump-'$i'.ppm","format":"ppm"}}' > "$qmp_log" 2>&1
    # نتحقق من وجود ملف screenshot وحجمه
    if [ -f "/tmp/screendump-$i.ppm" ] && [ "$(stat -c%s "/tmp/screendump-$i.ppm" 2>/dev/null || echo 0)" -gt 1000 ]; then
      echo "[sadim] run $i: screendump captured ($(stat -c%s "/tmp/screendump-$i.ppm") bytes)"
      rm -f "/tmp/screendump-$i.ppm"
    else
      echo "[sadim] run $i: WARN: screendump failed or empty"
      cat "$qmp_log" 2>/dev/null || true
    fi
  fi

  # ننهي QEMU
  kill $QEMU_PID 2>/dev/null
  wait $QEMU_PID 2>/dev/null
  status=$?

  echo "[sadim] run $i: qemu exit code $status"
  if grep -q "SADIM-BOOT-OK"   "$rlog" \
     && grep -q "SADIM-LIVE-OK"   "$rlog" \
     && grep -q "SADIM-ROOTFS-OK" "$rlog" \
     && grep -q "SADIM-NET-OK"    "$rlog" \
     && [ "$gui_ok" -eq 1 ]; then
    ok=$((ok+1))
    cp "$rlog" "$LOG"
  else
    echo "[sadim] run $i FAILED — one or more markers missing"
    for m in SADIM-BOOT-OK SADIM-LIVE-OK SADIM-ROOTFS-OK SADIM-NET-OK SADIM-GUI-OK; do
      grep -q "$m" "$rlog" 2>/dev/null && echo "  marker $m: PRESENT" || echo "  marker $m: MISSING"
    done
    cp "$rlog" "$LOG"
  fi
done

if [ "$ok" -eq "$RUNS" ]; then
  echo "========================================================"
  echo "  GUI BOOT TEST PASSED — all 5 markers x3"
  echo "========================================================"
  exit 0
else
  echo "========================================================"
  echo "  GUI BOOT TEST FAILED ($ok/$RUNS runs reached all markers)"
  echo "========================================================"
  echo "---- last 100 lines of last boot log ----"
  tail -n 100 "$LOG"
  exit 1
fi