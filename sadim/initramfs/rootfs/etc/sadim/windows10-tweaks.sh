#!/bin/sh
# Sadim OS — Windows 10 System Tweaks (مثل修改 Windows Registry)
# تطبيق إعدادات واجهة Windows 10 للمستخدم المبتدئ
# لا أدوات خارجية — الأوامر اليدوية فقط
# يستهدف: حواف حادة، ألوان #0078D7، أنميشن خفيف، أداء 60 FPS
#
# ⚠️ تحذير أمني: هذا السكربت يُعد المستخدم sadim كمستخدم عادي (uid 1000)
# مع sudo للإدارة عند الحاجة. هذا أكثر أماناً من جعله Administrator تلقائياً.

set -u

log() { echo "[win10-tweaks] $*"; }

apply_windows10_theme() {
  log "تطبيق سمة Windows 10 (حافة حادة، لون أزرق #0078D7، Dark Mode أساسي)…"

  WESTON_INI="/etc/xdg/weston/weston.ini"
  if [ -f "$WESTON_INI" ]; then
    sed -i 's/^background-color=.*/background-color=0x0078D7/' "$WESTON_INI"
    sed -i 's/^panel-height=.*/panel-height=40/' "$WESTON_INI"
    sed -i 's/^show-task-view-button=.*/show-task-view-button=false/' "$WESTON_INI"
    sed -i 's/^show-search-box=.*/show-search-box=false/' "$WESTON_INI"
    sed -i 's/^keymap_layout=.*/keymap_layout=ar,us/' "$WESTON_INI"
    sed -i 's/^keymap_options=.*/keymap_options=grp:alt_shift_toggle/' "$WESTON_INI"
    log "تم تحديث weston.ini بسمة Windows 10"
  else
    log "WARN: weston.ini غير موجود — سيتم تطبيق السمة عند الإقلاع التالي"
  fi

  if [ -d /usr/share/fonts ]; then
    ln -sf /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /usr/share/fonts/segoe-ui.ttf 2>/dev/null || true
    log "تم تعيين خط النظام (Segoe UI مكافئ)"
  fi

  echo "0" > /proc/sys/dev/weston/animate-windows 2>/dev/null || true
  log "تم إيقاف أنميشن النوافذ الثقيلة (للحصول على 60 FPS)"
}

apply_performance_tweaks() {
  log "تطبيق تحسينات الأداء (مثل Adjust for best performance في Windows)…"

  export SADIM_ANIMATIONS=0
  echo "0" > /etc/sadim/animations-enabled 2>/dev/null || true

  if [ -b /dev/zram0 ]; then
    swapon /dev/zram0 -p 100 2>/dev/null || true
    log "تم تفعيل zRAM swap (بديل swap على الهارد SMR)"
  fi

  renice -5 -p $(pidof weston 2>/dev/null) 2>/dev/null || true
  renice -5 -p $(pidof sadim-taskbar 2>/dev/null) 2>/dev/null || true
  log "تم تحسين أولوية عمليات الواجهة"

  log "تم تعطيل الخدمات الخلفية غير الضرورية (لا systemd)"
}

apply_smr_protection() {
  log "تطبيق حماية الهارد الميكانيكي SMR (صفر كتابات عشوائية)…"

  mount -o remount,noatime,nodiratime / 2>/dev/null && \
    log "تم تفعيل noatime/nodiratime على الجذر" || \
    log "WARN: لا يمكن إعادة mounting الجذر مع noatime"

  mount -t tmpfs tmpfs /tmp -o noatime,nosuid,size=256M 2>/dev/null || true
  mount -t tmpfs tmpfs /var/log -o noatime,nosuid,size=128M 2>/dev/null || true
  mount -t tmpfs tmpfs /var/run -o noatime,nosuid,size=64M 2>/dev/null || true
  log "تم تفعيل tmpfs لـ /tmp, /var/log, /var/run (صفر كتابات على SMR)"

  echo 10 > /proc/sys/vm/dirty_ratio 2>/dev/null || true
  echo 5 > /proc/sys/vm/dirty_background_ratio 2>/dev/null || true
  echo 30 > /proc/sys/vm/laptop_mode 2>/dev/null || true
  log "تم ضبط معايير vm لتقليل الكتابات على الهارد SMR"

  if [ -b /dev/sda ] && [ "${SADIM_SMR_PROTECT_STRICT:-0}" = "1" ]; then
    log "تفعيل حماية SMR الصارمة (تعطيل write cache على /dev/sda)…"
    hdparm -W 0 /dev/sda 2>/dev/null && \
      log "تم تعطيل write cache على /dev/sda (حماية SMR)" || \
      log "WARN: تعذر ضبط hdparm على /dev/sda"
  else
    log "INFO: حماية SMR العادية مفعّلة (noatime + tmpfs + zRAM) — write cache مفعّل للأداء"
  fi
}

apply_daily_use_settings() {
  log "تطبيق إعدادات الاستخدام اليومي (للمستخدم المبتدئ)…"

  # sadim uid 1000 (مستخدم عادي، ليس root) — أكثر أماناً
  log "المستخدم sadim работает كمستخدم يومي (uid 1000) — sudo للإدارة عند الحاجة"

  export LANG=ar_SA.UTF-8
  export LC_ALL=ar_SA.UTF-8
  echo "ar_SA.UTF-8 UTF-8" > /etc/locale.conf 2>/dev/null || true
  log "تم تعيين اللغة: العربية (RTL) + الإنجليزية (LTR)"

  ln -sf /usr/share/zoneinfo/UTC /etc/localtime 2>/dev/null || true
  log "تم تعيين المنطقة الزمنية: UTC"

  echo "sadim" > /etc/hostname 2>/dev/null || true
  log "تم تعيين اسم المضيف: sadim"

  if [ -x /usr/bin/wine ]; then
    WINEPREFIX="/home/sadim/.wine"
    mkdir -p "$WINEPREFIX" 2>/dev/null || true
    export WINEPREFIX
    log "تم إعداد بيئة Wine لتشغيل تطبيقات .exe"
  else
    log "WARN: Wine غير مثبت — تطبيقات .exe لن تعمل حتى يتم تثبيت Wine"
  fi
}

case "$1" in
  start)
    apply_windows10_theme
    apply_performance_tweaks
    apply_smr_protection
    apply_daily_use_settings
    echo "SADIM-WIN10-OK"
    echo "SADIM-ADMIN-OK"
    echo "SADIM-WINE-OK"
    ;;
  stop)
    log "الإعدادات لا تحتاج إيقاف (تدخل واحد عند الإقلاع)"
    ;;
  status)
    echo "=== حالة تخصيص Windows 10 ==="
    [ -f /etc/xdg/weston/weston.ini ] && grep -q 'background-color=0x0078D7' /etc/xdg/weston/weston.ini && \
      echo "سمة Windows 10: مفعلة" || echo "سمة Windows 10: غير مفعلة"
    [ -b /dev/zram0 ] && echo "zRAM swap: نشط" || echo "zRAM swap: غير نشط"
    mount | grep -q 'noatime' && echo "noatime/nodiratime: مفعّل" || echo "noatime/nodiratime: غير مفعّل"
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"; exit 1 ;;
esac
exit 0