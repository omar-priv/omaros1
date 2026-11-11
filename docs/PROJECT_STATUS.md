# PROJECT_STATUS — حالة المشروع الحية

> آخر تحديث: 2026-11-11 (الجلسة الجارية). هذا الملف يحدَّث باستمرار وفق تكليف مالك المشروع.

## المرحلة الحالية

**المرحلة 2 — Kernel + Initramfs + QEMU** (جارية) بعد إتمام المرحلتين 0 و1.

| # | المرحلة | الحالة |
|---|---|---|
| 0 | فحص البيئة والعتاد | ✅ مكتملة (قياسات موثقة) |
| 1 | Research + قرار ADR-001 | ✅ مكتملة (8 مصادر روابط) |
| **2** | **نواة مبنية من المصدر + initramfs + إقلاع QEMU في CI** | 🔄 **جارية — كود البناء والاختبار مكتوب؛ بانتظار مستودع GitHub لتشغيل CI الفعلي** |
| 3 | rootfs + مستخدمون + صلاحيات + خدمات | ⏳ |
| 4 | سطح المكتب المخصص (RTL/LTR) | ⏳ |
| 5 | التطبيقات الأساسية | ⏳ |
| 6 | العتاد والتعريفات على الجهاز الحقيقي | ⏳ |
| 7 | الأداء والأمان | ⏳ |
| 8 | إصدار ISO تجريبي | ⏳ |

## ما تم تنفيذه فعلياً حتى الآن

- نواة 6.12.117 LTS **مثبتة الإصدار** (تحقق من kernel.org/releases.json بتاريخ 2026-11-11).
- `sadim/kernel/`: build.sh (tinyconfig + fragment المشروع → bzImage) — بلا Docker/WSL محلياً.
- `sadim/initramfs/`: BusyBox 1.36.1 ثابت + **init خاص بـ Sadim OS v0.1** (وسم `SADIM-BOOT-OK`).
- `sadim/ci/boot-test.sh`: QEMU بـ TCG، بوابة نجاح صارمة (الوسم + لا Panic).
- `.github/workflows/kernel-boot.yml`: يفشل عند فشل الإقلاع، ويحفظ bzImage/initramfs/لوج كـ Artifacts.
- ميثاق هندسي كامل + ADR-001 + دراسات بحثية بمصادر (docs/).

## ما تم اختباره ونتائجه

- فحوصات العتاد والبيئة (قراءة فقط، بلا admin): موثقة في `docs/research/hardware-discovery.md` — **نتجت فعلياً**: Legacy+MBR، بطارية 60%، معرفات PCI، VRAM 2GB.
- **اختبار الإقلاع: لم يُنفذ بعد** — يحتاج رفع الكود إلى GitHub Actions أولاً. لن يُعلَن نجاح المرحلة 2 قبل ظهور `SADIM-BOOT-OK` في لوج CI حقيقي.

## ما فشل وسبب الفشل

- `create_repository` عبر GitHub MCP: **403 Resource not accessible by personal access token**
  — التوكن المتصل لا يملك صلاحية إنشاء مستودعات. الحل المطلوب من المالك (انظر أدناه).
- (تاريخي) أداة اكتشاف العتاد من جلسة متوازية كانت تنتج تقارير فارغة — أُصلحت موثقاً.

## الملفات الجديدة/المعدلة (آخر جلسة)

- جديد: `sadim/kernel/{version.mk,build.sh,fragments/qemu-minimal.config}`،
  `sadim/initramfs/{build.sh,init}`، `sadim/ci/boot-test.sh`،
  `.github/workflows/kernel-boot.yml`، `docs/PROJECT_STATUS.md`.
- تعديل: `.gitignore` (مخارج sadim/)، `README.md` (الاسم الرسمي Sadim)،
  `docs/testing-strategy.md` (وسم SADIM-BOOT-OK)، `docs/roadmap.md` (ترقيم مراحل المالك).

## حالة GitHub Repository

- **الاسم الرسمي: `omaros1`** (Private) — **لم يُنشأ بعد** بسبب صلاحية التوكن (403).
- لا remote حتى الآن (حفاظاً على صحة الربط — سيضاف بـ origin بعد الإنشاء).

## آخر Commit

- راجع `git log --oneline` — آخر commit قبل هذه الجلسة: `a0cf3bf`؛
  commits المرحلة 2 ستُسجل بعد كتابة الملفات أعلاه.

## روابط Workflows / Artifacts / Releases

- Workflows: `sadim-ci` (lint، موجود) + `sadim-phase2-boot` (جديد) — **لن تعمل إلا بعد وجود المستودع**.
- Artifacts: سيُنتج `sadim-boot-<run_id>` (bzImage + initramfs + boot-log) من أول تشغيل ناجح.
- Releases: لا شيء بعد (المرحلة 8).

## ما تبقى من العمل (بترتيب أولوية)

1. إنشاء `omaros1` → ربط origin → فحص أسرار → Push → تشغيل workflow → **إثبات SADIM-BOOT-OK**.
2. تحويل النواة من «مينية QEMU» إلى تكوين مستهدف للجهاز (AHCI + i915 + ath10k + xHCI…) تدريجياً.
3. المرحلة 3: rootfs + مستخدمون/صلاحيات + خدمات + سجلات.
4. المرحلة 4-5: سطح المكتب والتطبيقات (قيد شرط HarfBuzz/Fribidi للعربية).

## ما يحتاج تدخل المالك الآن (خطوة واحدة)

**إنشاء المستودع `omaros1` بإحدى طريقتين:**
- (أ) يدوياً: github.com/new → الاسم `omaros1` → Private → **بدون** README/gitignore/license
  ثم أخبرني «تم»، وسأكمل الربط والرفع والتشغيل.
- (ب) ترقية صلاحيات توكن GitHub MCP: إضافة `Administration (read/write)` + `Contents (read/write)`
  + `Workflows (read/write)` على مستوى المستودعات، ثم أعد المحاولة — وسأنشئه بنفسي.
