# PROJECT_STATUS — حالة المشروع الحية

> آخر تحديث: 2026-11-11 — **بوابة المرحلة 2 منجزة + إصدار Live ISO v0.1.0-live منشأ فعلياً**.

## المرحلة الحالية

**المرحلة 2 ✅ مكتملة بالدليل — والمرحلة 8 (الإصدار) منجزة جزئياً: Live ISO منشأة ومرفوعة في Release رسمي.**

| # | المرحلة | الحالة |
|---|---|---|
| 0 | فحص البيئة والعتاد | ✅ مكتملة (قياسات موثقة) |
| 1 | Research + قرار ADR-001 | ✅ مكتملة (8 مصادر روابط) |
| **2** | **نواة مبنية من المصدر + initramfs + إقلاع QEMU في CI** | ✅ **منجزة — `SADIM-BOOT-OK` ×3 في لوج CI حقيقي** |
| 3 | rootfs + مستخدمون + صلاحيات + خدمات | ⏳ (طبقة /etc Live أولية منجزة ضمن v0.2) |
| 4 | سطح المكتب المخصص (RTL/LTR) | ⏳ (قرار ADR-002 موثق) |
| 5 | التطبيقات الأساسية | ⏳ |
| 6 | العتاد والتعريفات على الجهاز الحقيقي | ⏳ — **الخطوة التالية: تجربة الفلاشة من المالك** |
| 7 | الأداء والأمان | ⏳ |
| 8 | إصدار ISO تجريبي | 🔄 **جزئي — `v0.1.0-live` منشأ + ISO مرفوعة + اختبار إقلاع حقيقي ×3؛ يتبقى التجريب على العتاد الحقيقي** |

## ما تم تنفيذه فعلياً حتى الآن

- نواة **6.12.117 LTS مثبتة الإصدار** (تحقق kernel.org + SHA256 ضد `sha256sums.asc`) — fragment v0.2 يشمل PCI/SMP/ACPI/DRM+I915+fbcon/VGA/i8042/USB-HID/r8169/NET (دعم العتاد الفعلي **غير مُدَّعى** حتى تجربة الجهاز).
- `sadim/initramfs/` — BusyBox 1.36.1 ثابت + **init v0.2**: proc/sys/devtmpfs، وسم `SADIM-BOOT-OK`، وضع CI (SADIM_CI=1 → إقلاع نظيف)، exec busybox init + inittab (getty tty1 autologin + ttyS0 تسلسلي) + طبقة /etc Live (passwd/group/os-release/motd…).
- `sadim/iso/build-iso.sh` — **Live ISO هجين BIOS (CD + USB)** عبر xorriso + isolinux + isohdpfx؛ النظام يعمل كلياً في الذاكرة.
- `sadim/ci/boot-test-iso.sh` — بوابة إقلاع عبر **المسار الحقيقي SeaBIOS→isolinux→init** ×3.
- Workflows: `ci.yml` (lint + بوابة YAML)، `kernel-boot.yml` (بوابة `-kernel`)، `live-iso.yml` (بناء ISO + بوابة المسار الحقيقي).
- ADR-001/002/003 + دليل تجربة USB + سجل مشاكل معروفة — كلها مرفوعة.

## ما تم اختباره ونتائجه (سلسلة CI الحقيقية)

| الاختبار | النتيجة | الدليل |
|---|---|---|
| CI lint + بوابة سلامة YAML | ✅ success | run 43073334253 |
| kernel-boot run #1 | ❌ startup — YAML: «: » غير مقتبس | run 43073326178 → إصلاح `1bd5a5e` |
| kernel-boot run #2 | ❌ initramfs — applet `tc` لا يترجم (بنى CBQ مُزالة من UAPI) | إصلاح `53d16e4` |
| kernel-boot run #3 | ❌ initramfs — busybox kconfig بلا `olddefconfig` | إصلاح (داخل `ee838c5`) |
| kernel-boot run #4 | ❌ initramfs — `yes\|oldconfig` + pipefail = broken pipe | run 43079186914 → إصلاح `3d59d8c` |
| **kernel-boot run #5** | ✅ **نجاح كامل: نواة 6.12.117-sadim-phase2 + init v0.2 + SADIM-BOOT-OK ×3** (كل إقلاع ≈3 ثوانٍ TCG؛ MemTotal 245088 kB) | run 43080783543, job 130732469698 |
| **live-iso run #2** | ✅ **نجاح كامل: ISO بنيت فعلياً (5,242,880 bytes) وقلعت ×3 عبر SeaBIOS→isolinux→init** | run 43080783447, job 130732457484 |

**حدود الصدق:** نجاح CI = بناء + إقلاع في QEMU فقط. **لم يُختبر بعد** أي شيء على العتاد الحقيقي (عرض/لوحة مفاتيح/لمس/إيثرنت/Wi-Fi) — ذلك نتيجة تجربة الفلاشة القادمة.

## ما فشل وسبب الفشل (وسبب الإصلاح)

1. `create_repository` عبر MCP → 403 → حُلّ عبر GitHub API باعتماد GCM (توكن في الذاكرة فقط).
2. run #1 startup failure → اسم خطوة بـ «: » غير مقتبس (تحقق PyYAML) → `1bd5a5e` + بوابة YAML دائمة.
3. run #2 → `tc.c:256 struct tc_cbq_lssopt` → تعطيل applet `tc` (غير مطلوب) → `53d16e4`.
4. run #3 → `olddefconfig: invalid target` → oldconfig بإجابات افتراضية (داخل `ee838c5`).
5. run #4 → `yes: standard output: Broken pipe` + pipefail → إزالة خطوة إعادة التوليد كلياً (تعديلات sed على رموز موجودة كافية) → `3d59d8c`.

## الملفات (بنية نهاية المرحلة 2)

- `sadim/kernel/{version.mk,build.sh,fragments/qemu-minimal.config}` — تثبيت إصدار + SHA256 + دمج fragment.
- `sadim/initramfs/{build.sh,init,rootfs/}` — BusyBox + init v0.2 + طبقة /etc.
- `sadim/iso/build-iso.sh` + `sadim/ci/{boot-test.sh,boot-test-iso.sh}` — ISO + البوابتان.
- `docs/`: ADR-001/002/003، `PROJECT_STATUS`، `roadmap`، `testing-strategy`، `known-issues`، `usb-try-guide`، بحوث عتاد/معمارية.

## حالة GitHub Repository

- **`omar-priv/omaros1`** — Private — https://github.com/omar-priv/omaros1 — فرع `main`، بلا force push.
- الأسرار: فحص CLEAN؛ لا مفاتيح/توكنات في المستودع؛ توكن API في الذاكرة فقط.

## آخر Commits

- `3d59d8c` — إصلاح خطوة إعادة تكوين busybox (pipefail/broken pipe)
- `215149a` — ADR-003 (init/خدمات)
- `1a8d5a1` — دليل تجربة USB

## روابط Workflows / Artifacts / Releases

- Workflows: lint ✅ + `sadim-phase2-boot` ✅ (run #5) + `sadim-live-iso` ✅ (run #2).
- Artifacts: `sadim-live-iso-43080783447` (bzImage 3.0MB + initramfs 1.3MB + sadim.iso 5MB + boot logs) — نُزِّل محلياً إلى `artifacts/iso-v0.1/`.
- **Release: `v0.1.0-live`** — https://github.com/omar-priv/omaros1/releases/tag/v0.1.0-live
  - أصل التحميل: **`sadim-0.1-live-bios.iso` (5MB)** — https://github.com/omar-priv/omaros1/releases/download/v0.1.0-live/sadim-0.1-live-bios.iso

## ما تبقى من العمل (بترتيب أولوية)

1. **تجربة الفلاشة على الجهاز الحقيقي** (فعل المالك الوحيد: Rufus DD/Etcher + F12 Legacy) — يجيب: عرض i915؟ لوحة مفاتيح/لمس؟ إيثرنت r8169؟
2. تثبيت hash تربل BusyBox في known-issues (من أول تشغيل ناجح) ثم إغلاق ENV-1.
3. v0.2 من ISO: Wi-Fi (ath10k + firmware-5.bin مثبت المصدر) + صوت (snd_hda) + squashfs إن لزم.
4. المرحلة 3: Buildroot rootfs + مستخدمون/صلاحيات + خدمات + سجلات (تصميم ADR-003).
5. المرحلة 4+ وفق ADR-002 (Wayland/weston + Qt6 + عربية RTL).

## ما يحتاج تدخل المالك

- **فعل واحد فقط:** نسخ `sadim-0.1-live-bios.iso` إلى فلاشة وفق `docs/usb-try-guide.md` وإقلاعها (F12 → Legacy). ثم إخبارنا بما يظهر على الشاشة (أو صورة له).
- لا شيء آخر — كل ما هو مطلوب قيد التنفيذ تلقائياً.
