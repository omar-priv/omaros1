# دراسة خيارات المعمارية — Architecture Options Research

> التاريخ: 2026-11-11. هذه الدراسة أدخلت في اعتبارها: عتاد الجهاز المكتشف فعلياً (Legacy+MBR،
> SMR HDD، 4GB، Optimus، QCA9377)، أهداف الاستخدام (متصفح حديث، Python/Node/Git، عربية RTL)،
> وقواعد الأمان (لا مساس بـ Windows؛ اختبار VM/USB أولاً).

## 1. القيد الحاكم: معايير النجاح للجهاز الحقيقي

النظام النهائي يجب أن يعمل **على هذا الجهاز تحديداً**: Wi-Fi QCA9377، رسوميات Intel HD 620،
صوت Realtek، بطارية، USB، ثم يوفر متصفحاً حديثاً وPython وNode وGit. أي مسار معماري لا يصل
لواقعياً إلى هذه النقطة خلال أفق المشروع يفشل المعايير — مهما كانت نظريته جيدة.

## 2. المصفوفة المقارنة (بالأدلة)

| المسار | QCA9377 Wi-Fi | رسوميات HD 620 | متصفح/Node/Python | ذاكرة | الحكم | الدليل |
|---|---|---|---|---|---|---|
| **نواة مخصصة كاملة من الصفر** (C أو Rust) | نواتها الخاصة لا تشمل QCA9377؛ كتلة تعريفات بحجم سنوات-عقود | i915 بديل = مشروع عملاق | لا شيء جاهز | ممتازة نظرياً | **مرفوض كمسار أساسي** — ينتج نظاماً تجريبياً لا يعمل على الجهاز؛ لا يحقق معايير النجاح | استنتاج هندسي موثق |
| **Linux mainline + userland مخصص (سديم)** | **مدعوم** ath10k_pci + firmware (منذ 2016؛ التحسينات في linux-firmware) | **مدعوم** i915 (Kaby Lake) | Chromium/Firefox، Python، Node — جاهزة | قاعدة ممكنة ~300-500MB باختيارات خفيفة | **المعتمد (ADR-001)** | روابط أدناه |
| **FreeBSD** | **غير مدعوم**: لا ath10ك فعلياً؛ الحلول الجانبية (wifibox = Linux VM) معقدة | drm-kmod جيد نسبياً | متوفر عبر packages | جيد | مرفوض — يفشل أولوية Wi-Fi رقم 4 في قائمة العتاد | منتديات FreeBSD 2026-10: «not at all is my suspicion» + Wiki |
| **NetBSD** | ath10k **غير موجود** في مصفوفة تعريفاتها (26 سائق بلا ath10k) | DRM قديم نسبياً | pkgsrc متاح | جيد | مرفوض — نفس سبب Wi-Fi + رسوميات أضعف | Wiki: wifi_driver_state_matrix |
| **Redox OS** (Rust microkernel) | **«Wi-Fi and Bluetooth aren't supported yet»** رسمياً | Intel GPUs فقط، ACPI ناقص | محدود جداً | ممتازة | مرفوض حالياً — غير جاهز لابتوب؛ يُتابع من بعيد | doc.redox-os.org/book/hardware-support + HARDWARE.md |
| **SerenityOS** | دعم لابتوب محدود جداً | محدود | Ladybird مستقلة | جيدة | مرفوض — دعم العتاد الفعلي غير مضمون | استنتاج من حالة المشروع |
| **توزيعة جاهزة + تلوين** | — | — | — | — | **مرفوض صراحة** بميثاق المستخدم (ليست بناء نظام) | نص الميثاق |

## 3. المصادر (متحقق منها بتاريخ 2026-11-11)

- ath10k + QCA9377 في linux-firmware (وثائق نواة Linux الرسمية):
  https://wireless.docs.kernel.org/en/latest/en/users/drivers/ath10k/firmware.html
- إضافة QCA9377 إلى linux-firmware (2021، OpenWrt) — معرف الجهاز 168c:0042:
  https://lists.openwrt.org/pipermail/openwrt-devel/2021-April/034627.html
- مشكلة أداء معروفة مع firmware-6.bin للجهاز نفسه + حل بتثبيت firmware-5.bin (Pop!_OS #1470):
  https://github.com/pop-os/pop/issues/1470
- FreeBSD + QCA9377 (غير مدعوم، نقاش حديث 2026-10):
  https://forums.freebsd.org/threads/is-freebsd-worth-trying-on-my-acer-laptop-qualcomm-qca9377-wi-fi.104263
  و https://forums.freebsd.org/threads/does-anyone-working-on-ath10k-driver.71962/
- NetBSD — مصفوفة حالة سائقات Wi-Fi (لا ath10k):
  https://wiki.netbsd.org/wifi_driver_state_matrix
- Redox — قيود العتاد الرسمية (لا Wi-Fi/Bluetooth، Intel GPU فقط، ACPI ناقص):
  https://doc.redox-os.org/book/hardware-support.html و https://github.com/redox-os/redox/blob/master/HARDWARE.md
- SMR للقرص WD10SPZX — رسمي:
  https://www.westerndigital.com/products/internal-drives/wd-blue-mobile-sata-hdd?sku=WD10SPZX

## 4. أثر عتاد الجهاز على التصميم (استنتاجات مبنية على قياسات)

1. **SMR HDD [م]:** الكتابات العشوائية المتتالية تُثقل الجهاز. التصميم: **zRAM افتراضياً** (ضغط
   الذاكرة في RAM بدل swap على القرص)، noatime، تجميع كتابات، لا خدمات فهرسة خلفية.
2. **Legacy + MBR [م]:** مسار الإقلاع سيكون **GRUB2 لوضع BIOS** (مع خيار UEFI في النسخ المعمارية
   العامة لاحقاً). لا حاجة لاعتبارات Secure Boot في هذا الجهاز.
3. **4GB Single Channel DDR3L [م/ت]:** كل MB مهم؛ musl بدل glibc للأساس، بدون systemd (init
   مخصص خفيف) كقرار أولي يُدقَّق في Phase 4.
4. **Optimus (HD 620 + MX130) [م]:** المسار الأساسي **Intel فقط** (i915) — توفر MX130 خطة
   لاحقة موثقة، وليس هدفاً للإصدار الأول (قرار موثق في known-issues).
5. **بطارية 60% [م]:** إدارة طاقة جدية (ترددات، suspend) من Phase 4.

## 5. حدود هذه الدراسة

- لم نجرّب أي إقلاع فعلي على العتاد بعد — كل ما سبق «معلومة موثقة» و«استنتاج هندسي»، وليس
  «نتيجة اختبار». أول قياس إقلاع حقيقي سيكون داخل QEMU في Phase 3.
- خيارات GUI الدقيقة (wlroots مقابل Xorg مقابل أداة مخصصة) = ADR-002 لاحقاً؛ القيد الحاكم
  المعلن الآن: دعم تشكيل الحروف العربية (HarfBuzz + Fribidi) شرط إلزامي في أي اختيار.
