# PROJECT_STATUS — حالة المشروع الحية

> آخر تحديث: 2026-11-12 — commit `866987b` (جميع المراحل 0-11 مكتملة الكود ومرفوعة على main، CI يُنفذ):
> نواة 6.12.117 + initramfs v0.3 + Buildroot rootfs + Weston + Qt6base + Wi-Fi/صوت/طاقة/zRAM/مراقبة/SMR + ISO v0.2-daily + واجهة Windows 10-like كاملة + تعريفات تلقائية + Administrator تلقائياً + Brave Browser + Wine لدعم .exe + تطبيقات نظام كاملة (ملفات، مفكرة، حاسبة، مدير مهام، إعدادات، محطة أوامر، متصفح).

## المرحلة الحالية

جميع مراحل 0-11 مكتملة الكود ومرفوعة على main (commit `866987b`):

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
| **10** | **تعريفات تلقائية + Administrator + Brave + Wine** | ✅ كود مكتمل | تحميل تعريفات تلقائياً + Administrator تلقائياً + متصفح Brave + دعم .exe |
| **11** | **واجهة Windows 10-like كاملة (المتكاملة)** | ✅ **كود مكتمل** | ملفات، مفكرة، حاسبة، مدير مهام، إعدادات، محطة أوامر، متصفح |

## ما تم تنفيذه فعلياً حتى الآن (commit `866987b`)

### النواة (6.12.117-sadim-phase4 + v0.5 fragment):
- PCI/SMP/ACPI/DRM+i915+fbcon/VGA/i8042/USB-HID/r8169/NET
- VIRTIO_GPU + squashfs/overlay/iso9660 + وسائط live حقيقية (ATA/SCSI/USB_STORAGE)
- **مرحلة 6:** ath10k_pci (Wi-Fi QCA9377)، snd-hda-intel/realtek/hdmi (صوت)، battery/ac/thermal (طاقة/بطارية)، USB OHCI/EHCI/UAS (flasha USB 2.0)، Synaptics/Elantech (لمس)، NTFS/FAT/EXT4، CRYPTO (SHA256/AES)

### initramfs (BusyBox 1.36.1 ثابت + init v0.3):
- proc/sys/devtmpfs، وسم `SADIM-BOOT-OK`، وضع CI (SADIM_CI=1)
- مسار live rootfs (squashfs+overlayfs+switch_root)
- طبقة /etc Live واحدة للحقيقة

### خدمات init.d (المراحل 3-11):
- S05-logging، S10-network (DHCP حقيقي)، S20-seatd، S30-weston، S99-ci-end
- **S35-drivers-load:** تحميل جميع تعريفات العتاد تلقائياً عند الإقلاع (modprobe لكل التعريفات)
- **S45-brave-install:** تثبيت Brave Browser تلقائياً من موقعه الرسمي
- **S50-sound:** ALSA Realtek HD Audio + Intel Display Audio
- **S60-power:** battery/ac/thermal، مراقبة صحة البطارية (≈60%)
- **S70-zram:** zRAM swap 256MB — **بديل swap على الهارد SMR** (لا كتابات على الهارد)
- **S80-monitor:** مراقبة تلقائية RAM/CPU/IO/حرارة/قرص كل 5 دقائق → /var/log/sadim-monitor.log
- **S90-smr-optimize:** noatime/nodiratime، dirty_ratio، laptop_mode، writeback — **حل بطئ الهارد الميكانيكي**
- **S15-windows10-shell:** تشغيل واجهة Windows 10-like (Taskbar + Start Menu)
- **windows10-tweaks.sh:** تخصيصات Windows 10 + Administrator تلقائياً + تكوين Wine

### التطبيقات الأساسية الشبيهة بـ Windows 10 (المراحل 9-11):
| التطبيق | المسار | الوصف |
|---------|--------|-------|
| **شريط المهام (Taskbar)** | `/usr/bin/sadim-taskbar` | زر ابدأ، أيقونات مثبتة، ساعة، مؤشر لغة، معلومات النظام |
| **قائمة ابدأ (Start Menu)** | `/usr/bin/sadim-start-menu` | تطبيقات أساسية، زر إيقاف التشغيل/إعادة التشغيل |
| **مستكشف الملفات (File Explorer)** | `/usr/bin/sadim-file-explorer` | مثل Windows Explorer (تنقل، نسخ، حذف، إعادة تسمية) |
| **المفكرة (Notepad)** | `/usr/bin/sadim-notepad` | مثل Windows Notepad (فتح/حفظ ملفات نصية UTF-8) |
| **الحاسبة (Calculator)** | `/usr/bin/sadim-calculator` | مثل Windows Calculator (عمليات أساسية، ذاكرة) |
| **مدير المهام (Task Manager)** | `/usr/bin/sadim-task-manager` | مثل Windows Task Manager (عمليات، معالج، ذاكرة، حالة) |
| **الإعدادات (Settings)** | `/usr/bin/sadim-settings` | مثل Windows Settings (اللغة، الوقت، الشاشة، الطاقة، الشبكة، حول النظام) |
| **محطة الأوامر (Terminal)** | `/usr/bin/sadim-terminal` | مثل Windows Command Prompt (أوامر النظام مباشرة) |
| **متصفح الويب (Browser)** | `/usr/bin/sadim-browser` | مثل Windows Edge/Chrome (يشغل Brave أو lynx أو links) |
| **تشغيل تطبيقات .exe (Wine)** | `/usr/bin/sadim-wine` | مثل Windows (تشغيل تطبيقات Windows عبر Wine) |

### متصفح الويب (مرحلة 10):
- **Chromium:** مثبت عبر Buildroot (حزمة رسمية)
- **Brave Browser:** يتم تثبيته تلقائياً من موقعه الرسمي عند الإقلاع الأول عبر S45-brave-install
- الرابط: https://brave.com/

### دعم تطبيقات Windows .exe (مرحلة 10):
- **Wine:** مثبت عبر Buildroot مع Wine Gecko و Wine Mono
- **sadim-wine:** سكريبت مساعدة لتشغيل ملفات .exe (الاستخدام: `sadim-wine <ملف.exe>`)
- يسبق الإقلاع الأول إعداد بنية Wine (wineprefix) في /home/sadim/.wine

### الصلاحيات (مرحلة 10):
- **sadim يمتلك uid 0 و gid 0** → يعمل ك Administrator تلقائياً عند كل إقلاع
- لا حاجة لكلمة مرور للدخول اليومي
- autologin يسجل الدخول تلقائياً ك sadim (معادل root)
- ⚠️ تحذير أمني: هذا يمنح sadim صلاحيات كاملة على النظام

### ملفات النظام (etc):
- etc/xdg/weston/weston.ini: سمة Windows 10 (#0078D7، panel-height=40، أيقونات سطح المكتب، no task-view/search)
- etc/sadim/windows10-tweaks.sh: تخصيصات الأداء و SMR + تعيين Administrator تلقائياً + تكوين Wine
- etc/fstab: tmpfs لـ /tmp, /var/log, /var/run, /var/tmp — **صفر كتابات عشوائية على SMR**
- etc/inittab: مستخدم sadim تلقائياً (Administrator) + getty على tty1 و ttyS0
- etc/autologin: `/bin/login -f sadim` (تسجيل دخول تلقائي آمن)
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
| **commit 866987b (جميع المراحل 0-11)** | 🔄 CI يعمل على جميع البوابات | جارٍ التشغيل على GitHub Actions |

## حدود الصدق (مهم جداً)

- نجاح CI = بناء + إقلاع في **QEMU فقط**. لم يُختبر أي شيء على العتاد الحقيقي بعد.
- **لم يُختبر على الجهاز الحقيقي:** عرض i915، لوحة مفاتيح/لمس i8042، إيثرنت r8169، Wi-Fi QCA9377، صوت Realtek، بطارية، Brave Browser، Wine، جميع التطبيقات.
- **تطبيقات .exe عبر Wine:** تتطلب اختباراً على العتاد الحقيقي لتأكيد التوافق.
- **لا يُسمح بمس أي قسم من أقسام Windows أو القرص الداخلي** — النظام يعمل ك-Live من USB فقط.
- التجربة على العتاد الحقيقي require inserting الفلاشة وإقلاع الجهاز من F12 → Legacy.

## ما يحتاجه منك (المالك) لتفعيل الاستخدام اليومي

### الخطوة المطلوبة منك (فعل واحد فقط):

1. بعد نجاح CI على commit `866987b` (سترى النتائج على GitHub Actions)، نزّل إصدار `v0.2-daily` من Releases
2. اكتب الصورة على **فلاشة USB 2.0** باستخدام Rufus (DD mode) أو balenaEtcher أو الأمر `dd`
3. أدرج الفلاشة في Acer E5-576G
4. أعد التشغيل واضغط **F12** → اختر الفلاشة → اختر **Legacy BIOS**
5. أبلغني بما يظهر:
   - هل ظهرت شاشة تسجيل دخول sadim ك Administrator تلقائياً؟
   - هل ظهر شريط المهام وقائمة ابدأ؟
   - هل يعمل اللمس والكيبورد؟
   - هل يتصل Wi-Fi (QCA9377)؟
   - هل يعمل الصوت (Realtek)؟
   - هل يفتح متصفح Brave؟
   - هل ينجح تشغيل ملف .exe عبر Wine؟
   - هل ظهرت أي أخطاء أو Kernel Panic؟

2. **مراقبة CI**: إذا فشلت أي بوابة على commit `866987b`, سيتم إصلاح السبب من المنبع وإعادة الدفع تلقائياً.

## روابط Workflows / Releases

- Workflows على main: `sadim-ci` + `sadim-phase2-boot` + `sadim-phase3-rootfs` + `sadim-phase4-gui` + `sadim-live-iso`
- Release `v0.1.0-live`: https://github.com/omar-priv/omaros1/releases/tag/v0.1.0-live
- إصدار `v0.2-daily` سيُنشأ تلقائياً بعد نجاح CI على commit `866987b`.

## آخر Commits

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
