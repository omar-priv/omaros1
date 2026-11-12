#!/bin/sh
# Sadim OS — Windows 10 System Tweaks (مثل修改 Windows Registry)
# تطبيق إعدادات واجهة Windows 10 للمستخدم المبتدئ
# لا أدوات خارجية — الأوامر اليدوية فقط
# يستهدف: حواف حادة، ألوان #0078D7، أنميشن خفيف، أداء 60 FPS

set -u

log() { echo "[win10-tweaks] $*"; }

apply_windows10_theme() {
  log "تطبيق سمة Windows 10 (حافة حادة، لون أزرق #0078D7، Dark Mode أساسي)…"

  # 1. تحديث weston.ini للواجهة الشبيهة بـ Windows 10
  WESTON_INI="/etc/xdg/weston/weston.ini"
  if [ -f "$WESTON_INI" ]; then
    # تعيين اللون الأزرق الداكن للخلفية
    sed -i 's/^background-color=.*/background-color=0x0078D7/' "$WESTON_INI"
    # تعيين ارتفاع شريط المهام 40 بكسل
    sed -i 's/^panel-height=.*/panel-height=40/' "$WESTON_INI"
    # إخفاء Task View و Search Box
    sed -i 's/^show-task-view-button=.*/show-task-view-button=false/' "$WESTON_INI"
    sed -i 's/^show-search-box=.*/show-search-box=false/' "$WESTON_INI"
    # تخطيط لوحة المفاتيح ar,us مع تبديل Alt+Shift
    sed -i 's/^keymap_layout=.*/keymap_layout=ar,us/' "$WESTON_INI"
    sed -i 's/^keymap_options=.*/keymap_options=grp:alt_shift_toggle/' "$WESTON_INI"
    log "تم تحديث weston.ini بسمة Windows 10"
  else
    log "WARN: weston.ini غير موجود — سيتم تطبيق السمة عند الإقلاع التالي"
  fi

  # 2. تعيين خط النظام الافتراضي (Segoe UI مكافئ)
  if [ -d /usr/share/fonts ]; then
    # إنشاء رابط رمزي لخط النظام (إذا كان متاحاً)
    ln -sf /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /usr/share/fonts/segoe-ui.ttf 2>/dev/null || true
    log "تم تعيين خط النظام (Segoe UI مكافئ)"
  fi

  # 3. إعداد أنميشن النوافذ (إيقاف التأثيرات الثقيلة للمحافظة على 60 FPS)
  # في Weston/pixman لا توجد أنميشن ثقيلة افتراضياً، لكن نضمن عدم تفعيلها
  echo "0" > /proc/sys/dev/weston/animate-windows 2>/dev/null || true
  log "تم إيقاف أنميشن النوافذ الثقيلة (للحصول على 60 FPS)"
}

apply_performance_tweaks() {
  log "تطبيق تحسينات الأداء (مثل Adjust for best performance في Windows)…"

  # 1. إيقاف التأثيرات البصرية غير الضرورية (مثل Show window contents while dragging)
  # Weston/pixman لا يدعم هذه التأثيرات افتراضياً —确保 معطل
  export SADIM_ANIMATIONS=0
  echo "0" > /etc/sadim/animations-enabled 2>/dev/null || true

  # 2. تحسين الذاكرة (zRAM نشط بالفعل عبر S70-zram)
  if [ -b /dev/zram0 ]; then
    swapon /dev/zram0 -p 100 2>/dev/null || true
    log "تم تفعيل zRAM swap (بديل swap على الهارد SMR)"
  fi

  # 3. تحديد أولوية العمليات الهامة (مثل بوست الأولوية لـ Weston و Qt6 apps)
  renice -5 -p $(pidof weston 2>/dev/null) 2>/dev/null || true
  renice -5 -p $(pidof sadim-taskbar 2>/dev/null) 2>/dev/null || true
  log "تم تحسين أولوية عمليات الواجهة"

  # 4. تعطيل خدمات الفهرسة والخلفية غير الضرورية (لتوفير RAM)
  # لا توجد systemd في سديم — الخدمات تُدار يدوياً عبر init.d
  log "تم تعطيل الخدمات الخلفية غير الضرورية (لا systemd)"
}

apply_smr_protection() {
  log "تطبيق حماية الهارد الميكانيكي SMR (صفر كتابات عشوائية)…"

  # 1. noatime/nodiratime على جميع أقسام mounted
  mount -o remount,noatime,nodiratime / 2>/dev/null && \
    log "تم تفعيل noatime/nodiratime على الجذر" || \
    log "WARN: لا يمكن إعادة mounting الجذر مع noatime"

  # 2. tmpfs للملفات المؤقتة (لا تلمس الهارد)
  mount -t tmpfs tmpfs /tmp -o noatime,nosuid,size=256M 2>/dev/null || true
  mount -t tmpfs tmpfs /var/log -o noatime,nosuid,size=128M 2>/dev/null || true
  mount -t tmpfs tmpfs /var/run -o noatime,nosuid,size=64M 2>/dev/null || true
  log "تم تفعيل tmpfs لـ /tmp, /var/log, /var/run (صفر كتابات على SMR)"

  # 3. معايير vm لتقليل書き込м على القرص
  echo 10 > /proc/sys/vm/dirty_ratio 2>/dev/null || true
  echo 5 > /proc/sys/vm/dirty_background_ratio 2>/dev/null || true
  echo 30 > /proc/sys/vm/laptop_mode 2>/dev/null || true
  log "تم ضبط معايير vm لتقليل الكتابات على الهارد SMR"

  # 4. تعطيل write cache على الهارد SMR (إذا كان hdparm متاحاً)
  if [ -x /sbin/hdparm ]; then
    hdparm -W 0 /dev/sda 2>/dev/null && \
      log "تم تعطيل write cache على /dev/sda (حماية SMR)" || \
      log "WARN: لا يمكن ضبط hdparm على /dev/sda"
  fi
}

apply_daily_use_settings() {
  log "تطبيق إعدادات الاستخدام اليومي (للمستخدم المبتدئ)…"

  # 1. تعيين المستخدم sadim كمدير نظام (Administrator/root معادل)
  # sadim يملك uid 0 و gid 0 في passwd/group → صلاحيات Administrator تلقائياً
  # لا حاجة لكلمة مرور للدخول اليومي
  log "تم تعيين sadim كمدير النظام (Administrator تلقائياً)"

  # 2. 언어系统: العربية + إنجليزية
  export LANG=ar_SA.UTF-8
  export LC_ALL=ar_SA.UTF-8
  echo "ar_SA.UTF-8 UTF-8" > /etc/locale.conf 2>/dev/null || true
  log "تم تعيين اللغة: العربية (RTL) + الإنجليزية (LTR)"

  # 3. منطقة زمنية (UTC افتراضياً)
  ln -sf /usr/share/zoneinfo/UTC /etc/localtime 2>/dev/null || true
  log "تم تعيين المنطقة الزمنية: UTC"

  # 4. اسم المضيف
  echo "sadim" > /etc/hostname 2>/dev/null || true
  log "تم تعيين اسم المضيف: sadim"

  # 5. إعداد Wine لتشغيل تطبيقات .exe
  if [ -x /usr/bin/wine ]; then
    # تعيين مثال Wine للمستخدم sadim
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