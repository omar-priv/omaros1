# اكتشاف العتاد — Hardware Discovery Report

> التاريخ: 2026-11-11. منهجية الوسم:
> **[م]** = قياس فعلي تم في هذه الجلسة بأوامر قراءة فقط بلا صلاحيات Administrator.
> **[ت]** = من تقرير الجهاز المقدم من المستخدم (لم يُعِد قياسه هنا).
> **[ل]** = لم يتحقق بعد (مذكور مع السبب وطريقة التحقق).
> لا يوجد في هذا التقرير أي كتابة على القرص الداخلي أو تعديل للنظام.

## 1. الحقائق الحرجة للقرار المعماري

| البند | النتيجة | الوسم | الطريقة |
|---|---|---|---|
| وضع الإقلاع | **Legacy BIOS** (وليس UEFI) | [م] | `$env:firmware_type` → `Legacy` |
| جدول الأقسام | **MBR** | [م] | `Get-Disk` → `PartitionStyle=MBR` مباشرة |
| بنية القرص | قرص واحد 931.5GB، 3 أقسام IFS (NTFS): 0.5GB (قسم إقلاع System Reserved)، C: 609.8GB، F: 321.2GB | [م] | `Get-Partition -DiskNumber 0` |
| Hyper-V hypervisor | مفعّل ويعمل الآن | [م] | `Win32_ComputerSystem.HypervisorPresent=True` |
| الذاكرة الحرة لحظة الفحص | **268MB فقط** من إجمالي 3973MB | [م] | `Win32_OperatingSystem` |
| VRAM NVIDIA MX130 | **2GB** (2147483648 بايت من السجل) | [م] | سجل `HKLM\...\Class\{4d36e968-...}` |
| VRAM Intel HD 620 | لا قيمة مسجلة — تستخدم **ذاكرة النظام المشتركة** (سلوك معروف لـ Intel) | [م]+[استنتاج] | نفس السجل: `MemorySize=` فارغ |
| صحة البطارية | **≈60%**: تصميم 40,880mWh / شحن كامل فعلي 24,572mWh، عداد دورات غير متاح (-) | [م] | `powercfg /batteryreport` (قراءة + تقرير مكتوب في `artifacts/`) |
| الصوت | Realtek High Definition Audio + Intel Display Audio (مسار HDMI) | [م] | `Win32_SoundDevice` |
| الشبكة | Wi-Fi: Qualcomm Atheros QCA9377 (مفعلة الآن)، Ethernet: Realtek PCIe GbE (معطلة)، Bluetooth PAN، محول Hyper-V افتراضي | [م] | `Win32_NetworkAdapter` |
| السائقون حالياً على Windows | Intel: 24.20.100.6286 (2018)، NVIDIA: 32.0.15.8253 | [م] | `Win32_VideoController` |

## 2. أجهزة الإدخال

- [م] لوحة اللمس تظهر كـ **«HID-compliant mouse» + أجهزة HID عامة** — بلا اسم ELAN/Synaptics صريح.
  **الاستنتاج الهندسي:** غالباً I2C-HID أو SMBus؛ بروتوكولها الحقيقي في Linux (i2c-hid مقابل PS/2/Elantech)
  **لم يتحقق بعد** — يحتاج إقلاع حي أو فحص ACPI. مدرجة في known-issues.
- [ت] لوحة المفاتيح مدمجة (QWERTY Latin) — تخطيطها الفعلي والدعم العربي يُتحقق منهما لاحقاً.

## 3. ما يحتاج صلاحيات Administrator (مؤجَّل مع السبب)

- **Secure Boot:** غير ذي معنى عملياً في وضع Legacy/MBR الحالي؛ طلب `Confirm-SecureBootUEFI` أعاد
  رفض صلاحيات. إن وجد وضع UEFI في BIOS لاحقاً يُعاد الفحص بموافقة صريحة.
- **TPM / BitLocker:** `Get-Tpm` أعاد «Administrator privilege is required». مؤجل — سنحتاجه فقط قبل
  أي قرار تثبيت، وسيُطلب إذن المستخدم صراحة حينها.
- **CYCLE COUNT للبطارية:** يعرض «-» (الجهاز لا يتيحه). ملاحظة: كلا قيمتي السعة قياس فعلي.

## 4. ملاحظات هندسية من الفحص

1. **SMR مؤكد من الصفحة الرسمية لـ WD** (WD10SPZX مذكور حرفياً ضمن SMR): كتابات عشوائية
   متتالية تسبب تجمدات إدخال/إخراج. أثره المعماري: zRAM بدل swap على القرص، noatime، كتابات مجمعة،
   لا فهرسة مستمرة. المصدر: https://www.westerndigital.com/products/internal-drives/wd-blue-mobile-sata-hdd?sku=WD10SPZX
2. **ذاكرة 4GB بSingle Channel (شريحة واحدة DDR3L-1600):** عرض النطاق محدود؛ إضافة شريحة ثانية
   (اختياري مستقبلاً بموافقة المستخدم) ترفع الأداء لكنها ليست مطلوبة للهدف.
3. **بطارية 60%:** وقت التشغيل قصير؛ إدارة الطاقة (suspend، ظبط ترددات) تُختبر لاحقاً على العتاد الحقيقي.
4. **قراءة الذاكرة الحرة (268MB) وأثناء تقرير المستخدم (164MB):** الجهاز يعمل تحت ضغط ذاكرة دائم مع
   Windows؛ هذا يؤكد الحاجة لنظام خفيف، ويقيد البناء المحلي الثقيل (سيعتمد على CI).
5. **الشاشة 1366×768 [ت]:** نطاق تصميم الواجهة الأساسي؛ اختبار درجات عرض أخرى في VM.

## 5. عناصر جاءت في تقرير المستخدم ولم تُعِد قياسها هنا [ت]

- BIOS: Insyde V1.47 (2018-09-06)، اللوحة: KBL/Ironman_SK.
- المعالج: i5-7200U 2C/4T، 2.5GHz أساس.
- USB/Camera/Mic: تُفحص في اختبارات العتاد الحية (المرحلة 7) — لا يوجد مسار آمن للفحص الآن من Windows
  دون أدوات خارجية، وتفاصيلها ستُوثق هناك.

## 6. سجل أدوات الفحص المستخدمة (قابلة للتكرار)

جميعها أوامر قراءة فقط، PowerShell 5.1، بلا صلاحيات مرتفعة:
`$env:firmware_type`، `Get-Disk`، `Get-Partition`، `Get-CimInstance` (Win32_DiskPartition/LogicalDisk/
VideoController/SoundDevice/NetworkAdapter/Battery/BatteryStaticData/BatteryFullChargedCapacity)،
سجل VRAM، `powercfg /batteryreport /output artifacts\battery-report.html`،
`Get-Command` لجرد الأدوات، `wsl --status`.
