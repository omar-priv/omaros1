# خارطة الطريق — Roadmap

> محدثة 2026-11-11 وفق ترقيم مراحل مالك المشروع في التكليف الرسمي.
> الأهداف أرقام معلنة تُقاس فعلياً — ليست نتائج مسبقة.

| # | المرحلة | المحتوى | الحالة | دليل الإتمام |
|---|---|---|---|---|
| 0 | فحص البيئة | جرد الأدوات، MCP (لا يوجد — موثق)، قيود الموارد | ✅ | docs/research/hardware-discovery.md |
| 1 | Research | اكتشاف عتاد، مقارنة معمارات، مصادر موثقة، ADR-001 | ✅ | docs/adr/ + docs/research/ |
| 2 | Kernel + Initramfs + QEMU | بناء نواة 6.12.117 من المصدر + fragment خاص + BusyBox + init المشروع + إقلاع آلي في CI | ✅ منجزة | **SADIM-BOOT-OK ×3** — run 43080783543، نواة `6.12.117-sadim-phase2` |
| 3 | نظام الملفات والخدمات | rootfs (Buildroot 2025.02.19 musl)، مستخدمون (root/sadim/seatd)، خدمات (S05/S10/S20/S30/S99)، DHCP حقيقي | ✅ كود مكتمل — CI يعمل | بوابة `sadim-phase3-rootfs`: 6 علامات ×3 — commit `a56efcf` |
| 4 | واجهة سطح المكتب | Weston (DRM+pixman)، seatd، eudev، Wayland، virtio-gpu، Arabic keymap (ar,us) | ✅ كود مكتمل — CI يعمل | بوابة `sadim-phase4-gui`: 7 علامات ×3 (+ QMP screendump) — commit `a56efcf` |
| 5 | التطبيقات الأساسية | Qt6base (linuxfb QPA، بلا OpenGL/EGL)، تطبيق اختبار RTL تجريبي في /opt/sadim-qt6-test/ | ✅ كود مكتمل — CI يعمل | جزء من rootfs عبر Buildroot — commit `a56efcf` |
| 6 | العتاد والتعريفات | HD620 (i915)، MX130 (مؤجلة)، QCA9377 (ath10k + firmware-5.bin)، صوت (snd-hda)، بطارية/طاقة، USB 2.0، لمس (Synaptics/Elantech) | ✅ كود مكتمل | kernel fragment v0.5 + rootfs حزم (linux-firmware, wpa_supplicant, alsa-utils, acpi, upower) — commit `a56efcf` |
| 7 | الأداء والأمان | zRAM swap (بديل swap على SMR)، noatime/nodiratime، tmpfs للملفات المؤقتة، مراقبة تلقائية RAM/CPU/IO/حرارة، laptop_mode | ✅ كود مكتمل | S70-zram، S80-monitor، S90-smr-optimize، etc/fstab — commit `a56efcf` |
| 8 | الإصدار اليومي | ISO هجينة BIOS+USB 2.0 مع جميع المراحل مدمجة، إصدار 0.2-daily | ✅ كود مكتمل — CI يعمل | iso/build-iso.sh + VERSION + خيارات إقلاع متعددة — commit `a56efcf` |
| **9** | **واجهة Windows 10-like للاستخدام اليومي** | Taskbar + Start Menu + File Explorer + Notepad + Calculator + Task Manager + سمة Windows 10 (#0078D7، حواف حادة، Dark Mode، سكريبتات تخصيص مثل Windows Registry) | ✅ كود مكتمل — CI يعمل | sadim-taskbar, sadim-start-menu, sadim-file-explorer, sadim-notepad, sadim-calculator, sadim-task-manager, etc/xdg/weston/weston.ini, etc/sadim/windows10-tweaks.sh, etc/init.d/S15-windows10-shell — commit `b731e65` |

## أهداف قياس معلنة (تُقاس فعلياً قبل أي إعلان نجاح)

- **الذاكرة عند الخمول بعد إقلاع كامل بالواجهة:** هدف ≤ 1GB؛ طموح ≈ 600MB. طريقة القياس: `/proc/meminfo`
  + تبويب، بعد استقرار 5 دقائق، متوسط 3 تشغيلات.
- **زمن الإقلاع:** من GRUB إلى سطح مكتب جاهز — يُقاس بطوابع زمنية في kernel/init/الواجهة.
- **صفر كتابات عشوائية متواصلة على HDD عند الخمول:** مراقبة `iostat` لمدة 10 دقائق خمول.
- **عربية RTL كاملة في الواجهة** (تشكيل صحيح + تبديل Alt+Shift): قائمة فحص UI/UX مكتوبة.

## الأدوات المكتشفة فعلياً (تقيد آلية التنفيذ)

- المضيف: Windows 10 (19045)، **Legacy BIOS**، RAM حرة 268MB [م] → لا بناء ثقيل محلياً.
- المتاح محلياً: Git 2.54، Python 3.11، tar، curl. **غير المتاح:** QEMU، WSL distro (النواة مفقودة)،
  gcc/nasm/make، Docker — لذا البناء والاختبار عبر **GitHub Actions** حتى يُدرَك (بموافقة) تثبيت محلي.
- **لا MCP مُهيأ** — فحص فعلي: بديل الأدوات المدمجة موثق في ميثاق المهارات (ملحق أ).

## قيود زمنية معلنة

بناء Linux كامل في CI (2 core): ~20-40 دقيقة للنواة؛ Buildroot الأساسي ~15-30 دقيقة — مقبول لـ CI
الليلي/الأسبوعي. لا مواعيد وهمية: كل مرحلة تُغلق بمعيار دليلها.
