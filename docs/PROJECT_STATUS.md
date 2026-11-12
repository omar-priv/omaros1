# PROJECT_STATUS — حالة المشروع الحية

> آخر تحديث: 2026-11-12 — commit `41e64b8` (مراحل 4+5 مرفوعة، CI يُنفذ): نواة 6.12.117 + initramfs v0.3 + Buildroot rootfs (مرحلة 3) + واجهة weston (مرحلة 4) + Qt6base (مرحلة 5).

## المرحلة الحالية

**المرحلة 2 ✅ مكتملة بالدليل** — نواة 6.12.117-sadim-phase2/phase4 + initramfs + إقلاع QEMU (`SADIM-BOOT-OK` ×3).
**المرحلة 8 (الإصدار) ✅ جزئي** — Live ISO v0.1.0-live منشأ ومرفوع في Release رسمي، اختبار إقلاع حقيقي ×3 نجح.
**المرحلة 3 🔄 جارية** — Buildroot 2025.02.19 (musl) + init v0.3 (squashfs+overlayfs) + خدمات init.d + DHCP حقيقي — بوابة `sadim-phase3-rootfs` قيد التشغيل على CI.
**المرحلة 4 🔄 جارية** — Weston (DRM+pixman) + seatd + eudev + virtio-gpu + QMP screendump — بوابة `sadim-phase4-gui` قيد التشغيل على CI.
**المرحلة 5 🔄 جارية** — Qt6base (linuxfb، بلا OpenGL/EGL) + تطبيق اختبار RTL عربي — جزء من rootfs عبر Buildroot.

| # | المرحلة | الحالة | دليل الإتمام |
|---|---|---|---|
| 0 | فحص البيئة والعتاد | ✅ مكتملة | docs/research/hardware-discovery.md |
| 1 | Research + قرار ADR-001 | ✅ مكتملة | docs/adr/ + docs/research/ |
| **2** | **نواة مبنية من المصدر + initramfs + إقلاع QEMU في CI** | ✅ **منجزة** | `SADIM-BOOT-OK` ×3 — kernel-boot run #5 (43080783543) |
| 3 | rootfs + مستخدمون + صلاحيات + خدمات | 🔄 **CI يعمل** | Buildroot 2025.02.19 +init v0.3 + خدمات + DHCP — بوابة `sadim-phase3-rootfs` |
| 4 | سطح المكتب المخصص (RTL/LTR) | 🔄 **CI يعمل** | Wayland/weston + seatd + virtio-gpu — بوابة `sadim-phase4-gui` |
| 5 | التطبيقات الأساسية | 🔄 **CI يعمل** | Qt6base linuxfb + تطبيق RTL تجريبي في `/opt/sadim-qt6-test/` |
| 6 | العتاد والتعريفات على الجهاز الحقيقي | ⏳ | تنتظر تجربة الفلاشة من المالك (F12 Legacy) |
| 7 | الأداء والأمان | ⏳ | قياسات RAM/إقلاع/IO + Threat Model — fase 7 |
| 8 | إصدار ISO تجريبي | 🔄 **جزئي** | `v0.1.0-live` منشئ + ISO 5MB مرفوعة + إقلاع حقيقي ×3 (43080783447) |

## ما تم تنفيذه فعلياً حتى الآن (commit `41e64b8`)

- نواة **6.12.117 LTS** مثبتة الإصدار (تحقق kernel.org + SHA256 ضد `sha256sums.asc`) — fragment v0.4 يشمل PCI/SMP/ACPI/DRM+i915+fbcon/VGA/i8042/USB-HID/r8169/NET + VIRTIO_GPU + squashfs/overlay/iso9660 + وسائط live حقيقية (ATA/SCSI/USB_STORAGE).
- `sadim/initramfs/` — BusyBox 1.36.1 ثابت + **init v0.3**: proc/sys/devtmpfs، وسم `SADIM-BOOT-OK`، وضع CI (SADIM_CI=1 → إقلاع نظيف)، مسار live rootfs (squashfs+overlayfs+switch_root)، طبقة /etc Live.
- `sadim/rootfs/` — Buildroot 2025.02.19 (musl+C++، locale، dynamic libs) مع overlay سديم واحد للحقيقة: passwd/group (root, sadim, seatd)، inittab، rcS، خدمات init.d (S05-logging, S10-network, S20-seatd, S30-weston, S99-ci-end).
- حزم المرحلة 4 في rootfs: weston 14.0.1 (DRM backend, pixman renderer), seatd, eudev, wayland, wayland-protocols, libinput, libdrm, libdisplay-info, libxkbcommon, xkeyboard-config, cairo, pixman, freetype, harfbuzz, fribidi, fontconfig.
- حزم المرحلة 5 في rootfs: Qt6base (core/gui/widgets/network/sql/sqlite/xml/test, linuxfb QPA, fontconfig, harfbuzz, png, jpeg).
- تطبيق اختبار Qt6 RTL في `/opt/sadim-qt6-test/main.cpp` + build.sh.
- `sadim/iso/build-iso.sh` — Live ISO هجين BIOS (CD + USB) عبر xorriso + isolinux + isohdpfx.
- Workflows: `ci.yml` (lint + YAML gate)، `kernel-boot.yml` (مرحلة 2)، `rootfs.yml` (مرحلة 3)، `live-iso.yml` (الإصدار)، `gui.yml` (مرحلة 4 مع QMP socat).
- ADR-001/002/003/004 + دليل تجربة USB + سجل مشاكل معروفة — كلها مرفوعة.

## ما تم اختباره ونتائجه (سلسلة CI الحقيقية)

| الاختبار | النتيجة | الدليل |
|---|---|---|
| CI lint + بوابة سلامة YAML | ✅ success | run 43073334253 |
| kernel-boot run #5 | ✅ نجاح كامل | `6.12.117-sadim-phase2` + `SADIM-BOOT-OK` ×3 | run 43080783543 |
| live-iso run #2 | ✅ نجاح كامل | ISO 5,242,880 bytes، إقلاع ×3 عبر SeaBIOS→isolinux→init | run 43080783447 |
| CI-5 بوابة بصمة BusyBox | ✅ `busybox-1.36.1.tar.bz2: OK` | runs 43085770179 + 43085770298 |
| **sadim-phase3-rootfs (commit 41e64b8)** | 🔄 قيد التشغيل | 4 علامات ×3: BOOT, LIVE, ROOTFS, NET |
| **sadim-phase4-gui (commit 41e64b8)** | 🔄 قيد التشغيل | 5 علامات ×3: + GUI عبر QMP screendump |
| **sadim-live-iso (commit 41e64b8)** | 🔄 قيد التشغيل | ISO كاملة + إقلاع حقيقي عبر المسار الحقيقي |
| **sadim-ci (commit 41e64b8)** | 🔄 قيد التشغيل | lint + بوابة YAML +秘密الفحص |

## حدود الصدق

نجاح CI = بناء + إقلاع في QEMU فقط. **لم يُختبر بعد** أي شيء على العتاد الحقيقي (عرض i915، لوحة مفاتيح/لمس i8042، إيثرنت r8169، Wi-Fi QCA9377، صوت) — ذلك نتيجة تجربة الفلاشة القادمة من المالك.

## ما تبقى من العمل (بترتيب أولوية)

1. **مراقبة نتائج CI** لـ commit `41e64b8` — التأكد من مرور بوابات rootfs (4 علامات ×3) و gui (5 علامات ×3) و live-iso.
2. **تجربة الفلاشة على الجهاز الحقيقي** (فعل المالك فقط: Rufus DD/Etcher + F12 Legacy) — تجيب: عرض i915؟ لوحة مفاتيح/لمس؟ إيثرنت؟ تسجيل النتائج في known-issues/PROJECT_STATUS.
3. **مرحلة 6:** تعريفات العتاد على الجهاز الحقيقي (ath10k + firmware-5.bin، snd_hda، طاقة، بطارية).
4. **مرحلة 7:** قياسات الأداء والأمان (RAM ≤ 1GB خمول، زمن إقلاع، صفر كتابات عشوائية على SMR، ثغرات الصلاحيات).
5. **مرحلة 8:** إصدار v0.2 من ISO مع تجميع كل المراحل + توثيق USB نهائي.

## ما يحتاج تدخل المالك

- فعل واحد: نسخ `sadim-0.1-live-bios.iso` (أو إصدار لاحق) إلى فلاشة وفق `docs/usb-try-guide.md` وإقلاعها (F12 → Legacy)، ثم الإبلاغ بما يظهر.
- مراقبة CI: إذا فشلت أي بوابة، يتم إصلاح السبب من المنبع وإعادة الدفع.

## روابط Workflows / Artifacts / Releases

- Workflows: `sadim-ci` + `sadim-phase2-boot` + `sadim-phase3-rootfs` + `sadim-phase4-gui` + `sadim-live-iso` (جميعها على main).
- **Release: `v0.1.0-live`** — https://github.com/omar-priv/omaros1/releases/tag/v0.1.0-live
  - أصل التحميل: **`sadim-0.1-live-bios.iso` (5MB)** — https://github.com/omar-priv/omaros1/releases/download/v0.1.0-live/sadim-0.1-live-bios.iso

## آخر Commits

- `41e64b8` — Phase 4+5: weston/seatd/eudev + Qt6base linuxfb + seatd user + VIRTIO_GPU kernel fragment
- `fec2421` — Phase 5: Qt6base (linuxfb backend) + Arabic RTL test app
- `07bf757` — Phase 4: GUI stack (weston DRM+pixman, seatd, eudev) + virtio-gpu + QMP screendump gate
- `036fd1b` — ISO v0.2 integration: live rootfs mandatory in image
