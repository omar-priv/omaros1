# PROJECT_STATUS — حالة المشروع الحية

> آخر تحديث: 2026-11-12 — commit `fe83fd4` (جميع المراحل 0-13 مكتملة الكود ومرفوعة على main، CI يُنفذ):
> نواة 6.12.117 + initramfs v0.5 + Buildroot rootfs + Weston + Qt6base + Wi-Fi/صوت/طاقة/zRAM/مراقبة/SMR + ISO v0.2-daily + واجهة Windows 10-like كاملة + أمان محسّن (sudo، عدم تشغيل ك root، SHA256 لـ Brave) + ميزات نظام متكاملة (مدير حزم، تحديث نظام، مراقبة قرص SMR، إدارة Wi-Fi، مراقبة الطاقة، شاشة قفل، بحث النظام).

## المرحلة الحالية

جميع مراحل 0-13 مكتملة الكود ومرفوعة على main (commit `fe83fd4`):

| # | المرحلة | الحالة | المحتوى |
|---|---|---|---|
| 0 | فحص البيئة والعتاد | ✅ مكتملة | أدوات، MCP، قيود الموارد |
| 1 | Research + ADR-001 | ✅ مكتملة | اكتشاف عتاد، مقارنة معمارية |
| **2** | **نواة + Initramfs + QEMU** | ✅ منجزة | نواة 6.12.117 + `SADIM-BOOT-OK` ×3 |
| **3** | **rootfs + خدمات + DHCP** | ✅ كود مكتمل | Buildroot 2025.02.19 (musl) + 6 علامات ×3 |
| **4** | **سطح المكتب (Weston)** | ✅ كود مكتمل | DRM+pixman + seatd + 7 علامات ×3 + QMP screendump |
| **5** | **التطبيقات الأساسية** | ✅ كود مكتمل | Qt6base linuxfb + تطبيق RTL عربي |
| **6** | **تعريفات العتاد الحقيقي** | ✅ كود مكتمل | Wi-Fi ath10k، صوت snd-hda، طاقة/بطارية، USB 2.0، لمس |
| **7** | **الأداء والأمان** | ✅ كود مكتمل | zRAM swap، SMR-optimize، مراقبة تلقائية، laptop_mode |
| **8** | **إصدار ISO v0.2-daily** | ✅ كود مكتمل | ISO هجينة BIOS+USB 2.0 مع جميع المراحل |
| **9** | **واجهة Windows 10-like** | ✅ كود مكتمل | Taskbar + Start Menu + Core Apps + سمة Windows 10 |
| **10** | **تعريفات تلقائية + Brave + Wine** | ✅ كود مكتمل | تحميل تعريفات تلقائياً + متصفح Brave (مع SHA256) + دعم .exe |
| **11** | **واجهة Windows 10-like كاملة (المتكاملة)** | ✅ كود مكتمل | ملفات، مفكرة، حاسبة، مدير مهام، إعدادات، محطة أوامر، متصفح |
| **12** | **الأمان والميزات المتكاملة** | ✅ كود مكتمل | sudo للإدارة، sadim uid 1000 (مستخدم عادي)، مدير حزم، تحديث نظام، مراقبة قرص، Wi-Fi، طاقة |
| **13** | **إصلاحات أمنية وتوثيق نهائي** | ✅ **كود مكتمل** | تصحيح uid، sudoers، شاشة قفل، بحث، إعدادات شبكة، معلومات نظام، مساعدة |

## ما تم تنفيذه فعلياً حتى الآن (commit `fe83fd4`)

### النواة (6.12.117-sadim-phase5 + v0.5 fragment):
- PCI/SMP/ACPI/DRM+i915+fbcon/VGA/i8042/USB-HID/r8169/NET
- VIRTIO_GPU + squashfs/overlay/iso9660 + وسائط live حقيقية (ATA/SCSI/USB_STORAGE)
- **مرحلة 6:** ath10k_pci (Wi-Fi QCA9377)، snd-hda-intel/realtek/hdmi (صوت)، battery/ac/thermal (طاقة/بطارية)، USB OHCI/EHCI/UAS (flasha USB 2.0)، Synaptics/Elantech (لمس)، NTFS/FAT/EXT4، CRYPTO (SHA256/AES)

### initramfs (BusyBox 1.36.1 ثابت + init v0.5):
- proc/sys/devtmpfs، وسم `SADIM-BOOT-OK`، وضع CI (SADIM_CI=1)
- مسار live rootfs (squashfs+overlayfs+switch_root)
- طبقة /etc Live واحدة للحقيقة

### خدمات init.d (المراحل 3-12):
- S05-logging، S10-network (DHCP حقيقي)، S20-seatd، S30-weston، S99-ci-end
- S35-drivers-load: تحميل جميع تعريفات العتاد تلقائياً عند الإقلاع
- S45-brave-install: تثبيت Brave Browser تلقائياً مع التحقق من SHA256
- S50-sound: ALSA Realtek HD Audio + Intel Display Audio
- S60-power: battery/ac/thermal، مراقبة صحة البطارية (≈60%)
- S70-zram: zRAM swap 256MB — بديل swap على الهارد SMR
- S80-monitor: مراقبة تلقائية RAM/CPU/IO/حرارة/قرص كل 5 دقائق
- S90-smr-optimize: noatime/nodiratime، dirty_ratio، laptop_mode، writeback — حل بطئ الهارد الميكانيكي
- S15-windows10-shell: تشغيل واجهة Windows 10-like (Taskbar + Start Menu)
- windows10-tweaks.sh: تخصيصات Windows 10 + تكوين Wine

### الصلاحيات والأمان (مرحلة 13 - إصلاحات حرجة):
- **sadim uid 1000** (مستخدم عادي، ليس root) — `etc/passwd`
- **sadim gid 1000** — `etc/group`
- **مجموعة sudo** (gid 27) مع sadim كعضو — للإدارة الآمنة عند الحاجة
- **ملف sudoers** — `etc/sudoers` — sadim يمكنه تشغيل أوامر إدارية محددة بدون كلمة مرور، والباقي يتطلب كلمة مرور
- **تسجيل دخول تلقائي ك sadim** (مستخدم عادي) — `etc/inittab` + `etc/autologin`
- **التحقق منSHA256** لتثبيت Brave Browser — `S45-brave-install` — prevents installing corrupted/tampered packages
- **تحذير أمني لـ Wine** — تطبيقات Windows غير موثوقة قد تشكل خطراً، مع طلب تأكيد قبل التشغيل
- **عدم تشغيل Wine ك root** — التحقق من `id -u` قبل التشغيل

### التطبيقات الأساسية الشبيهة بـ Windows 10 (المراحل 9-11):
| التطبيق | المسار | الوصف | مثل Windows |
|---------|--------|-------|-------------|
| **شريط المهام (Taskbar)** | `/usr/bin/sadim-taskbar` | زر ابدأ، أيقونات مثبتة، ساعة، مؤشر لغة، معلومات النظام | Windows 10 Taskbar |
| **قائمة ابدأ (Start Menu)** | `/usr/bin/sadim-start-menu` | تطبيقات أساسية، زر إيقاف التشغيل/إعادة التشغيل | Windows 10 Start Menu |
| **مستكشف الملفات (File Explorer)** | `/usr/bin/sadim-file-explorer` | مثل Windows Explorer (تنقل، نسخ، حذف، إعادة تسمية) | Windows Explorer |
| **المفكرة (Notepad)** | `/usr/bin/sadim-notepad` | مثل Windows Notepad (فتح/حفظ ملفات نصية UTF-8) | Windows Notepad |
| **الحاسبة (Calculator)** | `/usr/bin/sadim-calculator` | مثل Windows Calculator (عمليات أساسية، ذاكرة) | Windows Calculator |
| **مدير المهام (Task Manager)** | `/usr/bin/sadim-task-manager` | مثل Windows Task Manager (عمليات، معالج، ذاكرة، حالة) | Windows Task Manager |
| **الإعدادات (Settings)** | `/usr/bin/sadim-settings` | مثل Windows Settings (اللغة، الوقت، الشاشة، الطاقة، الشبكة، حول النظام) | Windows Settings |
| **محطة الأوامر (Terminal)** | `/usr/bin/sadim-terminal` | مثل Windows Command Prompt (أوامر النظام مباشرة) | Windows CMD |
| **متصفح الويب (Browser)** | `/usr/bin/sadim-browser` | مثل Windows Edge/Chrome (يشغل Brave أو lynx أو links) | Windows Edge |
| **تشغيل تطبيقات .exe (Wine)** | `/usr/bin/sadim-wine` | مثل Windows (تشغيل تطبيقات Windows عبر Wine، مع تحذير أمني) | Windows |
| **بحث النظام (Search)** | `/usr/bin/sadim-search` | بحث عن الملفات والتطبيقات والإعدادات | Windows Search |
| **شاشة القفل (Lock Screen)** | `/usr/bin/sadim-lock-screen` | قفل الشاشة مع طلب كلمة مرور | Windows Lock Screen |
| **مساعدة النظام (Help)** | `/usr/bin/sadim-help` | دليل استخدام النظام للمستخدم المبتدئ | Windows Help |

### متصفح الويب (مرحلة 10):
- **Chromium:** مثبت عبر Buildroot (حزمة رسمية)
- **Brave Browser:** يتم تثبيته تلقائياً من موقعه الرسمي عند الإقلاع الأول عبر S45-brave-install — **مع التحقق من SHA256**
- الرابط: https://brave.com/

### دعم تطبيقات Windows .exe (مرحلة 10):
- **Wine:** مثبت عبر Buildroot مع Wine Gecko و Wine Mono
- **sadim-wine:** سكريبت مساعدة لتشغيل ملفات .exe — **مع تحذير أمني وتحقق من عدم التشغيل ك root**
- يسبق الإقلاع الأول إعداد بنية Wine (wineprefix) في /home/sadim/.wine

### ميزات النظام المتكاملة (المراحل 12-13):
| الأداة | المسار | الوصف |
|--------|--------|-------|
| **مدير الحزم** | `/usr/bin/sadim-package-manager` | تثبيت، إزالة، قائمة، بحث، معلومات حول الحزم الإضافية |
| **تحديث النظام** | `/usr/bin/sadim-system-update` | فحص التحديثات من GitHub Releases، تحميل وتثبيت إصدار جديد |
| **مراقبة القرص SMR** | `/usr/bin/sadim-disk-health` | معلومات القرص، صحة S.M.A.R.T، أداء القراءة/الكتابة، مراقبة مستمرة |
| **إدارة Wi-Fi** | `/usr/bin/sadim-wifi-manager` | بحث عن الشبكات، الاتصال، قطع الاتصال، حالة الاتصال، الشبكات المحفوظة |
| **مراقبة الطاقة** | `/usr/bin/sadim-power-monitor` | حالة البطارية، صحة البطارية، درجة الحرارة، مراقبة مستمرة |
| **معلومات النظام** | `/usr/bin/sadim-system-info` | عرض معلومات العتاد والنظام والمكونات المثبتة |

### ملفات النظام (etc):
- etc/xdg/weston/weston.ini: سمة Windows 10 (#0078D7، panel-height=40، أيقونات سطح المكتب، no task-view/search)
- etc/sadim/windows10-tweaks.sh: تخصيصات الأداء و SMR + تكوين Wine
- etc/fstab: tmpfs لـ /tmp, /var/log, /var/run, /var/tmp — **صفر كتابات عشوائية على SMR**
- etc/inittab: مستخدم sadim تلقائياً (مستخدم عادي) + getty على tty1 و ttyS0
- etc/autologin: `/bin/login -f sadim` (تسجيل دخول تلقائي آمن)
- etc/sudoers: صلاحيات sudo للمستخدم sadim
- etc/group: sadim gid 1000، مجموعة sudo gid 27
- etc/passwd: sadim uid 1000 (مستخدم عادي، ليس root)
- etc/profile: إعدادات البيئة للمستخدم sadim
- etc/hosts, etc/hostname, etc/motd, etc/os-release, etc/issue, etc/securetty, etc/udhcpc.script
- os-release/issue/motd: الإصدار 0.2-daily مع واجهة Windows 10-like

### إصدار ISO (مرحلة 8):
- build-iso.sh: ISO هجينة BIOS+USB 2.0 عبر xorriso+isolinux+isohdpfx
- ملف VERSION مع تاريخ البناء والإصدار والنواة
- خيارات إقلاع متعددة: sadim (عادي)، safe (بدون ACPI)، memtest
- قابل للكتابة على فلاشة USB 2.0 عبر `dd`

### Workflows CI (جميعها على main):
- `sadim-ci`: lint + بوابة YAML + فحص الأسرار
- `sadim-phase2-boot`: بناء النواة + initramfs + إقلاع QEMU
- `sadim-phase3-rootfs`: rootfs + live boot + خدمات + DHCP + DRIVERS + HW + PERF + SHELL + WIN10 + ADMIN + WINE (11 علامة ×3)
- `sadim-phase4-gui`: Weston + seatd + virtio-gpu + QMP screendump + HW + PERF + DRIVERS + SHELL + WIN10 + ADMIN + WINE (12 علامة ×3)
- `sadim-live-iso`: ISO v0.2-daily + إقلاع حقيقي SeaBIOS→isolinux→init (11 علامة ×3)

## ما تم اختباره ونتائجه (سلسلة CI الحقيقية)

| الاختبار | النتيجة | الدليل |
|---|---|---|
| kernel-boot run #5 | ✅ `SADIM-BOOT-OK` ×3 | run 43080783543 |
| live-iso run #2 | ✅ ISO 5MB + إقلاع ×3 عبر SeaBIOS→isolinux→init | run 43080783447 |
| CI-5 بوابة بصمة BusyBox | ✅ `busybox-1.36.1.tar.bz2: OK` | runs 43085770179 + 43085770298 |
| **commit fe83fd4 (جميع المراحل 0-13)** | 🔄 CI يعمل على جميع البوابات | جارٍ التشغيل على GitHub Actions |

## حدود الصدق (مهم جداً)

- نجاح CI = بناء + إقلاع في **QEMU فقط**. لم يُختبر أي شيء على العتاد الحقيقي بعد.
- **لم يُختبر على الجهاز الحقيقي:** عرض i915، لوحة مفاتيح/لمس i8042، إيثرنت r8169، Wi-Fi QCA9377، صوت Realtek، بطارية، Brave Browser، Wine، جميع التطبيقات، جميع الأدوات الجديدة.
- **تطبيقات .exe عبر Wine:** تتطلب اختباراً على العتاد الحقيقي لتأكيد التوافق — **مع تحذير أمني**
- **لا يُسمح بمس أي قسم من أقسام Windows أو القرص الداخلي** — النظام يعمل ك-Live من USB فقط.
- التجربة على العتاد الحقيقي require inserting الفلاشة وإقلاع الجهاز من F12 → Legacy.

## ما يحتاجه منك (المالك) لتفعيل الاستخدام اليومي

### الخطوة المطلوبة منك (فعل واحد فقط):

1. بعد نجاح CI على commit `fe83fd4` (سترى النتائج على GitHub Actions)، نزّل إصدار `v0.2-daily` من Releases
2. اكتب الصورة على **فلاشة USB 2.0** باستخدام Rufus (DD mode) أو balenaEtcher أو الأمر `dd`
3. أدرج الفلاشة في Acer E5-576G
4. أعد التشغيل واضغط **F12** → اختر الفلاشة → اختر **Legacy BIOS**
5. أبلغني بما يظهر:
   - هل ظهرت شاشة تسجيل دخول sadim كمستخدم عادي (ليست root)؟
   - هل ظهر شريط المهام وقائمة ابدأ؟
   - هل يعمل اللمس والكيبورد؟
   - هل يتصل Wi-Fi (QCA9377)؟
   - هل يعمل الصوت (Realtek)؟
   - هل يفتح متصفح Brave (مع التحقق من SHA256)؟
   - هل ينجح تشغيل ملف .exe عبر Wine (مع التحذير الأمني)؟
   - هل تعمل جميع التطبيقات والأدوات الجديدة (ملفات، مفكرة، حاسبة، مدير مهام، إعدادات، محطة أوامر، متصفح، بحث، إعدادات شبكة، مراقبة قرص، مراقبة طاقة، معلومات نظام، مساعدة)؟
   - هل يمكن استخدام sudo للإدارة عند الحاجة؟
   - هل ظهرت أي أخطاء أو Kernel Panic؟

2. **مراقبة CI**: إذا فشلت أي بوابة على commit `fe83fd4`, سيتم إصلاح السبب من المنبع وإعادة الدفع تلقائياً.

## روابط Workflows / Releases

- Workflows على main: `sadim-ci` + `sadim-phase2-boot` + `sadim-phase3-rootfs` + `sadim-phase4-gui` + `sadim-live-iso`
- Release `v0.1.0-live`: https://github.com/omar-priv/omaros1/releases/tag/v0.1.0-live
- إصدار `v0.2-daily` سيُنشأ تلقائياً بعد نجاح CI على commit `fe83fd4`.

## آخر Commits

- `fe83fd4` — إصلاحات أمنية حرجة وميزات نظام متكاملة (المرحلة 13): sudo، عدم تشغيل ك root، SHA256 لـ Brave، مدير حزم، تحديث نظام، مراقبة قرص، Wi-Fi، طاقة، شاشة قفل، بحث، إعدادات شبكة
- `591aefd` — docs: توثيق المرحلة 12 (الأمان والميزات المتكاملة)
- `6ac1d65` — إصلاحات أمنية حرجة وميزات نظام متكاملة (المرحلة 12)
- `934f9d2` —docs: توثيق المرحلة 11 (واجهة Windows 10-like كاملة متكاملة)
- `866987b` — إصلاح المشاكل الحرجة وتطوير واجهة Windows 10-like الكاملة (المرحلة 11)
- `0b56334` — docs: توثيق المرحلة 10 (التعريفات التلقائية + Administrator + Brave + Wine)
- `be2da2d` — التعريفات التلقائية + Administrator تلقائياً + Brave Browser + Wine لدعم .exe
- `50f32bd` — المرحلة 9: واجهة Windows 10-like للاستخدام اليومي (المبتدئ)
- `b731e65` —docs: توثيق واجهة Windows 10-like (المرحلة 9) + جميع المراحل 0-8
- `a56efcf` — مراحل 6+7+8: العتاد الحقيقي، zRAM/SMR، مراقبة تلقائية، ISO v0.2-daily
- `41e64b8` — Phase 4+5: weston/seatd/eudev + Qt6base linuxfb + seatd user
- `fec2421` — Phase 5: Qt6base (linuxfb backend) + Arabic RTL test app
- `07bf757` — Phase 4: GUI stack (weston DRM+pixman, seatd, eudev) + virtio-gpu + QMP gate
- `036fd1b` — ISO v0.2 integration: live rootfs mandatory in image
