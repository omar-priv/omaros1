# ADR-002: حزمة العرض الرسومي (GUI Stack) لسديم OS

- **الحالة:** مقبول مبدئياً (Proposed → Accept) — التثبيت النهائي مشروط بإثبات عملي في المرحلة 4: عرض نص عربي مشكّل RTL صحيح + قياس استهلاك فعلي.
- **التاريخ:** 2026-11-11
- **القرار مرتبط بـ:** ADR-001 (المعمارية الأساسية).

## 1. السياق والقيود

الجهاز المستهدف: Acer E5-576G — i5-7200U، **RAM 4GB**، قرص HDD **SMR** (كتابة متسلسلة بطيئة — حجم حزم العرض يؤثر مباشرة)، رسوميات Intel HD 620 (8086:5916). المتطلب الرسمي: واجهة مخصصة لسديم، **عربية RTL + إنجليزية LTR بجودة أولى**، مظهر Windows-like، خفة استثنائية.

## 2. المتطلبات المقيّدة (R1-R6)

| # | المتطلب | معيار القياس |
|---|---|---|
| R1 | تشكيل نص عربي صحيح (الحروف المتصلة + الأشكال السياقية) | عرض «سديم» متصلة الحروف بلا تقطيع |
| R2 | ثنائية الاتجاه (bidi) للنص المختصر عربي/إنجليزي | ترتيب بصري صحيح للنص المختلط |
| R3 | انعكاس الواجهة على مستوى عناصر التحكم (قوائم، أزرار، شريط مهام) | RTL widget mirroring قياسي |
| R4 | بناء من المصدر عبر Buildroot (بدون ثنائيات مغلقة) | وجود الحزمة في Buildroot |
| R5 | وزن مناسب لـ 4GB + SMR | يُقاس فعلياً في المرحلة 7 (لا أرقام خيالية) |
| R6 | رخصة حرة | SPDX معروف لكل مكوّن |

## 3. طبقة النص (إلزامية في كل الخيارات): FreeType + HarfBuzz + Fribidi

الأدوار موثقة من مصادر رسمية:

- **HarfBuzz** = محرك التشكيل (shaping) فقط — كذلك يصرّح مطوروه: «HarfBuzz is only a text shaper» ([HarfBuzz README الرسمي](https://github.com/harfbuzz/harfbuzz)).
- **Fribidi** = خوارزمية Unicode BiDi (تحويل منطقي→بصري) — ومثال الحروف المختلطة موثق في [Modern text rendering with Linux](https://mrandri19.github.io/2019/07/24/modern-text-rendering-linux-overview.html).
- **FreeType** = التحويل النقطي (rasterization) للرموز — [نفس المصدر](https://mrandri19.github.io/2019/07/24/modern-text-rendering-linux-overview.html).
- الخط: **Noto Naskh Arabic** (رخصة OFL حرة) للنصوص العربية.

## 4. مقارنة بروتوكول العرض

| الخيار | الإيجابيات | السلبيات | الحكم |
|---|---|---|---|
| **Wayland + compositor مخصص** | لا عملية Xorg وسطى، مسار KMS مباشر عبر i915، يتيح «قشرة سديم» كمكوّن من مكوّنات العرض نفسها؛ أداء Wayland متفوق في المقارنات الحديثة ([Wayland vs X11: 2026](https://dev.to/rosgluk/wayland-vs-x11-2026-comparison-5cok)) | هندسة compositor أثقل (لكن مكتبات جاهزة: weston/libweston) | **مختار** |
| X11 + مدير نوافذ مخصص | نضج وأدوات كثيرة | عملية خادم إضافية، بلا فائدة مستقبلية، مسار إهمال تدريجي | خطة احتياط موثقة فقط |
| KMS/DRM مباشر بلا بروتوكول | أدنى وزن ممكن | إعادة بناء مشاكل نوافذ/إدخال من الصفر = مخاطرة ضخمة غير ضرورية | مرفوض |

ملاحظة صدق: أرقام استهلاك الذاكرة للـ compositors متضاربة في المجتمع ([نقاش HN](https://news.ycombinator.com/item?id=38516612)) — لذلك **لا يعتمد أي رقم هنا**؛ القياس الفعلي في المرحلة 7 (مهلة R5).

## 5. مقارنة عدة الواجهات (Toolkit)

| الخيار | R1-R2 (نص عربي) | R3 (RTL على مستوى العناصر) | R4 (Buildroot) | الحكم |
|---|---|---|---|---|
| **Qt6 Widgets** | مدمج (HarfBuzz داخلياً) | **موثق رسمياً** ([Qt RTL Docs](https://doc.qt.io/qt-6/qtquick-positioning-righttoleft.html) + دعم LayoutDirection للقوائم [مثال عملي](https://stackoverflow.com/questions/36295725/getting-qt-layout-direction-to-use-right-to-left-features-e-g-for-arabic-in-c)) | ✅ `package/qt6` (تحقق فعلي) | **مختار للتطبيقات** |
| GTK3 (Pango) | مدمج | ✅ widget direction | ✅ `package/libgtk3` (تحقق فعلي) | بديل احتياطي |
| FLTK | ❌ | ❌ — مشكلة رسمية مفتوحة تعترف بغياب الدعم ([fltk#1063](https://github.com/fltk/fltk/issues/1063)) | ✅ | **مرفوض** (يفشل R3) |
| عدة مخصصة بالكامل | ممكن (HarfBuzz+Fribidi مباشرة) | تكلفة هندسية ضخمة لكل عنصر | — | **مرفوض للتطبيقات**؛ يُسمح به لقشرة سديم لاحقاً فوق Wayland |

## 6. القرار

1. **D1 — بروتوكول العرض: Wayland.** أول مُركِّب عملي: **weston** (`package/weston` ✓) كمرجع تشغيل في المرحلة 4، ثم قشرة **سديم Shell** مخصصة فوق libweston أو wlroots.
2. **D2 — عدة التطبيقات: Qt6 Widgets** (`package/qt6` ✓) مع تنسيق مخصص QSS (هوية سديم) وتشذيب الوحدات (Widgets فقط — بلا WebEngine) للسيطرة على الحجم.
3. **D3 — طبقة النص:** FreeType + HarfBuzz + Fribidi + fontconfig + Noto Naskh Arabic (OFL).
4. **D4 — خطة احتياط موثقة فقط:** إذا أثبتت المرحلة 4 أن هندسة Wayland تعطل تقدماً حقيقياً، يُعاد فتح الخيار X11 + مدير نوافذ مخصص بقرار ADR جديد — لا صمت عن ذلك.

## 7. جدول الأدلة المُتحقق منها (بتاريخ 2026-11-11)

| الدليل | التحقق | الرابط |
|---|---|---|
| حزمة harfbuzz في Buildroot | فحص فعلي لمجلد `package/harfbuzz` | https://github.com/buildroot/buildroot/tree/master/package/harfbuzz |
| حزمة libfribidi (fribidi) | فحص فعلي | https://github.com/buildroot/buildroot/tree/master/package/libfribidi |
| حزم freetype/cairo/fontconfig/libdrm/sdl2/wayland | فحص فعلي | `package/…` في نفس المستودع |
| حزمة weston | فحص فعلي | `package/weston` |
| حزمة qt6 | فحص فعلي | `package/qt6` |
| حزمة libgtk3 | فحص فعلي | `package/libgtk3` |
| أدوار HarfBuzz/Fribidi/FreeType | مصدر تعليمي منظم + README رسمي | https://mrandri19.github.io/2019/07/24/modern-text-rendering-linux-overview.html |
| دعم RTL في Qt | وثائق رسمية | https://doc.qt.io/qt-6/qtquick-positioning-righttoleft.html |
| غياب دعم العربية في FLTK | مشكلة رسمية | https://github.com/fltk/fltk/issues/1063 |
| مقارنة Wayland/X11 حديثة | مقال 2026 | https://dev.to/rosgluk/wayland-vs-x11-2026-comparison-5cok |

## 8. العواقب والمخاطر

- **حجم Qt6 على قرص SMR:** يُشذَّب عبر Buildroot (لا WebEngine، لا Quick إلا عند الحاجة) — الهدف: targetfs للرسوميات ≤ 300MB (يُقاس، لا يُدّعى).
- **هندسة القشرة المخصصة:** أطول مساراً من X11 WM — مقبول لأن weston يغطي المرحلة 4 كمرجع.
- **إذا فشل R5 قياساً في المرحلة 7:** يُعاد فتح D2 بين Qt/GTK بقرار ADR مرقّم — لا تمادي.
