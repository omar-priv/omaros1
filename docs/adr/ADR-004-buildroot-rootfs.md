# ADR-004: الجذر الحي عبر Buildroot (المرحلة 3)

- **الحالة:** مقبول — منفَّذ فعلياً وبوابة CI خاصة به (`sadim-phase3-rootfs`).
- **التاريخ:** 2026-11-11
- **مرتبط بـ:** ADR-001 (اتجاه musl/BusyBox + بناء من المصدر)، ADR-003 (init/الخدمات).

## 1. السياق والقرار

المرحلة 2 أثبتت أن النظام يقلع (initramfs خام). المرحلة 3 تحتاج **جذر حقيقي** يستطيع استضافة
المراحل القادمة (سطح مكتب، تطبيقات). القرار: **Buildroot LTS 2025.02.19** لجلب مساحة المستخدم
(musl + busybox)، مع إبقاء النواة مبنية سكربتاتنا المثبتة (تثبيت إصدار + بصمة kernel.org).

## 2. الدليل (متحقق وقت القرار)

| البند | القيمة | المصدر |
|---|---|---|
| إصدار LTS | **2025.02.19** — دعم حتى مارس 2028 | buildroot.org/download.html (LTS table) |
| مسار التنزيل الفعلي | المرآة الرسمية github.com/buildroot/buildroot وسم `2025.02.19` | GitHub API: tag object `26cf1107…` موجود |
| سبب عدم buildroot.org المباشر | شهادة TLS منتهية عند 2026-11-11 (`ssl.SSLCertVerificationError: certificate has expired`) | محاولة تنزيل حقيقية موثقة (ENV-4) |
| بصمة التربل المثبتة | `0fc9583d1b019b42c0cf3ea1dc64899a2247ab9adbce47f47ac5d4cb13ce0c98` | تنزيل فعلي + sha256 + تثبيت في `sadim/rootfs/build.sh` مع `sha256sum -c` |

## 3. البنية المنفَّذة

```
[نواة 6.12.117 fragment v0.3: squashfs(xz/zlib) + overlayfs + iso9660 + virtio]
        │
[initramfs = محمّل فقط — busybox + init v0.3]
        │  يجد squashfs: /dev/vda (CI) أو sr0 (CD حقيقي: iso9660 + loop live/rootfs.squashfs)
        │  يركّب overlayfs (lower=squashfs, upper/work=tmpfs)  ← حيّ قابل للكتابة
        ▼  switch_root
[جذر مدمج = Buildroot rootfs.squashfs + طبقة سديم]
        /sbin/init (busybox) → /etc/inittab سديم → rcS v0.3 → /etc/init.d/S*
        S05-logging (سجل إقلاع فعلي) · S10-network (udhcpc حقيقي → SADIM-NET-OK)
        S99-ci-end (وضع بوابة CI → إقلاع نظيف)
```

- **مصدر واحد للحقيقة:** طبقة `/etc` سديم = `sadim/initramfs/rootfs/` نفسها تُستخدم كـ `BR2_ROOTFS_OVERLAY` —
  لا نسخ مكررة تتباعد.
- **سلسلة العلامات (كل علامة معنى حقيقي):** `SADIM-BOOT-OK` (وصل init) → `SADIM-LIVE-OK` (جذر مدمج
  جاهز) → `SADIM-ROOTFS-OK` (إطار الخدمات اكتمل على الجذر المدمج) → `SADIM-NET-OK` (إيجار DHCP فعلي).

## 4. بدائل مرفوضة ولماذا

| البديل | سبب الرفض |
|---|---|
| تكبير initramfs اليدوي | لا يستطيع استضافة weston/Qt6 بشكل واقعي في المراحل 4/5 (تبعيات متشعبة) |
| توزيعة كاملة (Debian/Alpine rootfs) | تخالف ADR-001 (بناء مضبوط من المصدر؛ حزم خارجية = سبق مُدعى بلا قياس) |
| Buildroot latest stable (2026.08) | LTS أطول عمراً للثبات — قرار مُعلن بإصدار مثبت |

## 5. حدود معلنة

- المسار اليدوي محلياً غير مدعوم (مضيف المالك بلا أدوات) — البناء في CI فقط.
- أي حزمة Buildroot إضافية مستقبلاً تمر عبر بوابة الإقلاع قبل أي ادعاء.
- الوسم يثبت بناء **التوزيعة في QEMU** — دعم العتاد الحقيقي يبقى غير مُدَّعى حتى تجربة المالك.
