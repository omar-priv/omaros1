# PROJECT_STATUS — حالة المشروع الحية

> آخر تحديث: 2026-11-11 (جلسة جارية). هذا الملف يحدَّث باستمرار وفق تكليف مالك المشروع.

## المرحلة الحالية

**المرحلة 2 — Kernel + Initramfs + QEMU** — كود البناء والاختبار مكتمل ومرفوع، CI يعمل فعلياً على GitHub.

| # | المرحلة | الحالة |
|---|---|---|
| 0 | فحص البيئة والعتاد | ✅ مكتملة (قياسات موثقة) |
| 1 | Research + قرار ADR-001 | ✅ مكتملة (8 مصادر روابط) |
| **2** | **نواة مبنية من المصدر + initramfs + إقلاع QEMU في CI** | 🔄 **CI lint ✅ أخضر + بناء النواة/الإقلاع قيد التشغيل — بوابة النجاح: `SADIM-BOOT-OK`** |
| 3 | rootfs + مستخدمون + صلاحيات + خدمات | ⏳ |
| 4 | سطح المكتب المخصص (RTL/LTR) | ⏳ |
| 5 | التطبيقات الأساسية | ⏳ |
| 6 | العتاد والتعريفات على الجهاز الحقيقي | ⏳ |
| 7 | الأداء والأمان | ⏳ |
| 8 | إصدار ISO تجريبي | ⏳ |

## ما تم تنفيذه فعلياً حتى الآن

- نواة **6.12.117 LTS مثبتة الإصدار** (تحقق من kernel.org/releases.json بتاريخ 2026-11-10) — بناء tinyconfig + fragment المشروع + تحقق SHA256 ضد `sha256sums.asc` من cdn.kernel.org.
- `sadim/kernel/` + `sadim/initramfs/` (BusyBox 1.36.1 ثابت + **init بـ Sadim OS v0.1**) + `sadim/ci/boot-test.sh` (بوابة 3 إقلاعات متتالية).
- `.github/workflows/kernel-boot.yml`: بناء كامل + اختبار إقلاع + Artifacts — يفشل الوهم مستحيلاً.
- **مستودع GitHub أنشئ فعلياً وارتبط وارُفع**: https://github.com/omar-priv/omaros1 (Private).
- ميثاق هندسي كامل + ADR-001 + دراسات بحثية بمصادر (docs/).

## ما تم اختباره ونتائجه

| الاختبار | النتيجة | الدليل |
|---|---|---|
| فحص العتاد والبيئة (قراءة فقط) | ✅ | `docs/research/hardware-discovery.md` |
| فحص صلاحية السكربتات محلياً (bash -n ×4) | ✅ | سجل الجلسة؛ `bash` الحقيقي = hermes\git\bin\bash.exe |
| فحص الأسرار (regex على كل الملفات المتتبعة) | ✅ CLEAN | سجل الجلسة |
| **CI lint على GitHub (job «سلامة بنية المشروع والوثائق»)** | ✅ **success** | run #1: github.com/omar-priv/omaros1/actions/runs/43073334253 |
| تشغيل #1 لـ kernel-boot.yml | ❌ **failure (startup)** — خطأ YAML: «: » غير مقتبس في اسم خطوة (سطر 51 عمود 38، تحقق PyYAML) | run: 43073326178 |
| **تشغيل #2 لـ kernel-boot.yml (بعد الإصلاح)** | 🔄 **قيد التشغيل/المتابعة** | الرفع `1bd5a5e` أطلقه تلقائياً |

**لن يُعلَن نجاح المرحلة 2 قبل ظهور `SADIM-BOOT-OK` في لوج CI حقيقي.**

## ما فشل وسبب الفشل (وسبب الإصلاح)

1. `create_repository` عبر MCP → 403 (التوكن بلا صلاحية إنشاء) → **حُلّ**: أنشئ فعلياً عبر GitHub API باعتماد GCM المخزّن لحساب `omar-priv` (توكن في الذاكرة فقط، بتفويض صريح من المالك).
2. `git ls-remote` → «Repository not found» قبل الإنشاء → سبب جذري صحيح: المستودع لم يكن موجوداً (تحقق بلا_guess عبر GCM `github list` = omar-priv).
3. **kernel-boot.yml run #1 → startup failure بلا jobs** → سبب جذري مؤكد: اسم خطوة يحوي «: » داخل نص YAML غير مقتبس (تحقق PyYAML: line 51 col 38) → أُصلح بالاقتباس + تحقق + إعادة رفع (`1bd5a5e`).

## الملفات الجديدة/المعدلة (آخر جلسة)

- جديد: `sadim/kernel/{version.mk,build.sh,fragments/qemu-minimal.config}`، `sadim/initramfs/{build.sh,init}`، `sadim/ci/boot-test.sh`، `.github/workflows/kernel-boot.yml`، `docs/PROJECT_STATUS.md`.
- تعديل: `.gitignore`، `README.md` (الاسم الرسمي Sadim + ترقيم المراحل)، `.github/workflows/ci.yml` (اسم sadim-ci)، `docs/{roadmap,testing-strategy,known-issues}.md`.
- إصلاح CI: اقتباس اسم خطوة في kernel-boot.yml.

## حالة GitHub Repository

- **`omar-priv/omaros1`** — Private — https://github.com/omar-priv/omaros1
- الربط: `origin` → HTTPS، فرع `main` يتتبع `origin/main`، **بلا force push**.
- الأسرار: فحص CLEAN قبل الرفع؛ لا مفاتيح/توكنات في المستودع؛ توكن API استُخدم في الذاكرة فقط ولم يُخزَّن أو يُعرض أبداً.

## آخر Commit

- `1bd5a5e` — Fix CI: quote step name containing colon-space (invalid YAML caused startup failure)
- السلسلة: `30e191e → 1ad7ed4 → a0cf3bf → aa252d9 → 1bd5a5e`

## روابط Workflows / Artifacts / Releases

- Workflows: `sadim-ci` (lint ✅ أخضر — run 43073334253) + `sadim-phase2-boot` (run #2 قيد التشغيل).
- Artifacts: سيُنتج `sadim-boot-<run_id>` (bzImage + initramfs + boot-logs) من أول تشغيل ناجح.
- Releases: لا شيء بعد (المرحلة 8).

## ما تبقى من العمل (بترتيب أولوية)

1. **إثبات `SADIM-BOOT-OK`** من لوج CI (قيد المتابعة الآن) — بوابة المرحلة 2.
2. تسجيل hash ثابت لتربل BusyBox (من أول تشغيل ناجح) في known-issues ثم إغلاقه.
3. ADR-002 (حزمة العرض الرسومي: شرط HarfBuzz+Fribidi للعربية) وADR-003 (init/خدمات).
4. تكوين نواة موسع مستهدف للجهاز (AHCI + i915 + ath10k + xHCI…) قبل المرحلة 6.
5. المرحلة 3: rootfs + مستخدمون/صلاحيات + خدمات + سجلات.

## ما يحتاج تدخل المالك

- **لا شيء الآن.** كل ما هو مطلوب قيد التنفيذ تلقائياً.
- لاحقاً (اختياري): ترقية صلاحيات توكن MCP (Administration/Contents/Workflows rw) لتشغيل عمليات GitHub مباشرة عبر MCP بدلاً من مسار GCM المحلي.
