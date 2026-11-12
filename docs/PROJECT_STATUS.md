# PROJECT_STATUS — حالة المشروع الحية

> آخر تحديث: 2026-11-12 — commit `a56efcf` (مراحل 6+7+8 مكتملة الكود، مرفوعة على main، CI يُنفذ):
> نواة 6.12.117 + initramfs v0.3 + Buildroot rootfs + Weston + Qt6base + Wi-Fi/صوت/طاقة/zRAM/مراقبة/SMR + ISO v0.2-daily.

## المرحلة الحالية

**المرحلة 2 ✅ مكتملة بالدليل** — نواة 6.12.117-sadim-phase4 + initramfs + إقلاع QEMU (`SADIM-BOOT-OK` ×3).
**المرحلة 3 ✅ مكتملة الكود** — Buildroot 2025.02.19 (musl) + init v0.3 (squashfs+overlayfs) + خدمات init.d + DHCP حقيقي — بوابة `sadim-phase3-rootfs` على CI.
**المرحلة 4 ✅ مكتملة الكود** — Weston (DRM+pixman) + seatd + eudev + virtio-gpu + QMP screendump — بوابة `sadim-phase4-gui` على CI.
**المرحلة 5 ✅ مكتملة الكود** — Qt6base (linuxfb، بلا OpenGL/EGL) + تطبيق اختبار RTL عربي — جزء من rootfs عبر Buildroot.
**المرحلة 6 ✅ مكتملة الكود** — تعريفات العتاد الحقيقي: ath10k (QCA9377 Wi-Fi)، snd-hda-intel (صوت Realtek)، battery/ac/thermal (طاقة وبطارية)، USB 2.0، لمس اللوحة، NTFS/FAT/EXT4.
**المرحلة 7 ✅ مكتملة الكود** — الأداء والأمان: zRAM swap (بديل swap على الهارد SMR)، مراقبة تلقائية (RAM/CPU/IO/حرارة)، noatime/nodiratime، tmpfs للملفات المؤقتة، laptop_mode.
**المرحلة 8 ✅ مكتملة الكود** — إصدار v0.2-daily: ISO هجينة BIOS+USB 2.0 مع جميع المراحل مدمجة.

| # | المرحلة | الحالة | دليل الإتمام |
|---|---|---|---|
| 0 | فحص البيئة والعتاد | ✅ مكتملة | docs/research/hardware-discovery.md |
| 1 | Research + قرار ADR-001 | ✅ مكتملة | docs/adr/ + docs/research/ |
| **2** | **نواة مبنية من المصدر + initramfs + إقلاع QEMU في CI** | ✅ **منجزة** | `SADIM-BOOT-OK` ×3 — kernel-boot run #5 (43080783543) |
| 3 | rootfs + مستخدمون + صلاحيات + خدمات | ✅ **كود مكتمل — CI يعمل** | Buildroot 2025.02.19 + init v0.3 + خدمات + DHCP — بوابة `sadim-phase3-rootfs` |
| 4 | سطح المكتب المخصص (RTL/LTR) | ✅ **كود مكتمل — CI يعمل** | Wayland/weston + seatd + virtio-gpu — بوابة `sadim-phase4-gui` |
| 5 | التطبيقات الأساسية | ✅ **كود مكتمل — CI يعمل** | Qt6base linuxfb + تطبيق RTL تجريبي في `/opt/sadim-qt6-test/` |
| 6 | العتاد والتعريفات على الجهاز الحقيقي | ✅ **كود مكتمل** | ath10k + firmware-5.bin، snd-hda، بطارية/طاقة، USB 2.0، لمس |
| 7 | الأداء والأمان | ✅ **كود مكتمل** | zRAM swap، SMR-optimize (noatime/writeback)، مراقبة تلقائية |
| 8 | إصدار ISO يومي | ✅ **كود مكتمل — CI يعمل** | `v0.2-daily` ISO هجينة BIOS+USB 2.0 — بوابة `sadim-live-iso` |

## ما تم تنفيذه فعلياً حتى الآن (commit `a56efcf`)

### النواة (6.12.117-sadim-phase4 + v0.5 fragment):
- PCI/SMP/ACPI/DRM+i915+fbcon/VGA/i8042/USB-HID/r8169/NET
- VIRTIO_GPU + squashfs/overlay/iso9660 + وسائط live حقيقية (ATA/SCSI/USB_STORAGE)
- **مرحلة 6:** ath10k_pci (Wi-Fi QCA9377)، snd-hda-intel/realtek/hdmi (صوت)، battery/ac/thermal (طاقة/بطارية)، USB OHCI/EHCI/UAS (flasha USB 2.0)، Synaptics/Elantech (لمس)، NTFS/FAT/EXT4، CRYPTO (SHA256/AES)

### initramfs (BusyBox 1.36.1 ثابت + init v0.3):
- proc/sys/devtmpfs، وسم `SADIM-BOOT-OK`، وضع CI (SADIM_CI=1)
- مسار live rootfs (squashfs+overlayfs+switch_root)
- طبقة /etc Live واحدة للحقيقة

### خدمات init.d (المراحل 3-9):
- S05-logging، S10-network (DHCP حقيقي)، S20-seatd، S30-weston، S99-ci-end
- **S40-wifi:** Wi-Fi QCA9377 مع wpa_supplicant + firmware-5.bin
- **S50-sound:** ALSA Realtek HD Audio + Intel Display Audio
- **S60-power:** battery/ac/thermal، مراقبة صحة البطارية (≈60%)
- **S70-zram:** zRAM swap 256MB — **بديل swap على الهارد SMR** (لا كتابات على الهارد)
- **S80-monitor:** مراقبة تلقائية RAM/CPU/IO/حرارة/قرص كل 5 دقائق → /var/log/sadim-monitor.log
- **S90-smr-optimize:** noatime/nodiratime، dirty_ratio، laptop_mode، writeback — **حل بطئ الهارد الميكانيكي**

### الجذر الحي (Buildroot 2025.02.19):
- musl + C++ + locale + dynamic libs
- حزم المرحلة 4: weston 14.0.1 (DRM+pixman)، seatd، eudev، wayland، harfbuzz/fribidi/fontconfig
- حزم المرحلة 5: Qt6base (linuxfb QPA، بلا OpenGL/EGL/GBM)، تطبيق RTL في `/opt/sadim-qt6-test/`
- **حزم المرحلة 6:** linux-firmware (ath10k QCA9377)، wpa_supplicant، iw، ip, alsa-utils، acpi، acpid، upower، dosfstools، ntfs-3g، e2fsprogs، lm-sensors
- **حزم المرحلة 7:** zram، sysstat، vmstat، iostat، dropbear (SSH)، nano، openssl، gnupg

### ملفات النظام (etc):
- fstab: tmpfs لـ /tmp, /var/log, /var/run, /var/tmp — **صفر كتابات عشوائية على SMR**
- inittab: مستخدم sadim يومي (ليس root تلقائياً) + getty على tty1 و ttyS0
- autologin: `/bin/login -f sadim` (تسجيل دخول تلقائي آمن)
- os-release/issue/motd: الإصدار 0.2-daily

### إصدار ISO (مرحلة 8):
- build-iso.sh: ISO هجينة BIOS+USB 2.0 عبر xorriso+isolinux+isohdpfx
- ملف VERSION مع تاريخ البناء والإصدار والنواة
- خيارات إقلاع متعددة: sadim (عادي)، safe (بدون ACPI)، memtest
- قابل للكتابة على فلاشة USB 2.0 عبر `dd`

### Workflows CI (جميعها على main):
- `sadim-ci`: lint + بوابة YAML + فحص الأسرار
- `sadim-phase2-boot`: بناء النواة + initramfs + إقلاع QEMU
- `sadim-phase3-rootfs`: rootfs + live boot + خدمات + DHCP (العلامات الست ×3)
- `sadim-phase4-gui`: Weston + seatd + virtio-gpu + QMP screendump (العلامات السبعة ×3)
- `sadim-live-iso`: ISO v0.2-daily + إقلاع حقيقي SeaBIOS→isolinux→init (العلامات الست ×3)

## ما تم اختباره ونتائجه (سلسلة CI الحقيقية)

| الاختبار | النتيجة | الدليل |
|---|---|---|
| kernel-boot run #5 | ✅ `SADIM-BOOT-OK` ×3 | run 43080783543 |
| live-iso run #2 | ✅ ISO 5MB + إقلاع ×3 عبر SeaBIOS→isolinux→init | run 43080783447 |
| CI-5 بوابة بصمة BusyBox | ✅ `busybox-1.36.1.tar.bz2: OK` | runs 43085770179 + 43085770298 |
| **commit a56efcf (مراحل 6+7+8)** | 🔄 CI يعمل على جميع البوابات | جارٍ التشغيل على GitHub Actions |

## حدود الصدق (مهم جداً)

- نجاح CI = بناء + إقلاع في **QEMU فقط**. لم يُختبر أي شيء على العتاد الحقيقي بعد.
- **لم يُختبر على الجهاز الحقيقي:** عرض i915، لوحة مفاتيح/لمس i8042، إيثرنت r8169، Wi-Fi QCA9377، صوت Realtek، بطارية.
- **لا يُسمح بمس أي قسم من أقسام Windows أو القرص الداخلي** — النظام يعمل ك-Live من USB فقط.
- التجربة على العتاد الحقيقي require inserting الفلاشة وإقلاع الجهاز من F12 → Legacy.

## ما يحتاجه منك (المالك) لتفعيل النظام للاستخدام اليومي

1. **تجربة الفلاشة على الجهاز الحقيقي** (فعل واحد فقط):
   - نزّل `sadim-0.2-daily-bios.iso` من Release القادمة (بعد نجاح CI)
   - اكتبها على فلاشة USB 2.0: `dd if=sadim.iso of=/dev/sdX bs=4M status=progress`
   - أدرج الفلاشة في Acer E5-576G، أعِد التشغيل، اضغط **F12**، اختر الفلاشة، اختر **Legacy**
   - أبلغني بما يظهر: هل وصل النظام إلى شاشة تسجيل الدخول؟ هل يعمل اللمس؟ هل يتصل Wi-Fi؟

2. **مراقبة CI**: إذا فشلت أي بوابة على commit `a56efcf`, سيتم إصلاح السبب من المنبع وإعادة الدفع تلقائياً.

## روابط Workflows / Releases

- Workflows على main: `sadim-ci` + `sadim-phase2-boot` + `sadim-phase3-rootfs` + `sadim-phase4-gui` + `sadim-live-iso`
- Release `v0.1.0-live`: https://github.com/omar-priv/omaros1/releases/tag/v0.1.0-live
- إصدار `v0.2-daily` سيُنشأ تلقائياً بعد نجاح CI على commit `a56efcf`.

## آخر Commits

- `a56efcf` — مراحل 6+7+8: العتاد الحقيقي، zRAM/SMR، مراقبة تلقائية، ISO v0.2-daily
- `41e64b8` — Phase 4+5: weston/seatd/eudev + Qt6base linuxfb + seatd user
- `fec2421` — Phase 5: Qt6base (linuxfb backend) + Arabic RTL test app
- `07bf757` — Phase 4: GUI stack (weston DRM+pixman, seatd, eudev) + virtio-gpu + QMP gate
- `036fd1b` — ISO v0.2 integration: live rootfs mandatory in image
