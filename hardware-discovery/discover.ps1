# =============================================================================
# Hardware Discovery Tool — Acer Aspire E5-576G
# أداة اكتشاف العتاد الآمنة — لجمع معلومات العتاد الناقصة من Windows
# =============================================================================
# ملاحظة: هذا السكريبت يعمل على Windows لجمع معلومات العتاد قبل بناء نظام التشغيل.
# لا يعدّل أي شيء على النظام، لا يكتب إلى أقسام القرص، لا يحتاج Admin إلا عند
# استعلام بعض العتاد المحمي (مثل TPM وBitLocker).
# جميع المخرجات تُحفظ في مجلد artifacts/ ولا تحتوي على بيانات شخصية
# (رقم تسلسلي، MAC Address، Product ID).
#
# سجل الإصلاحات:
# - 2026-11-11: إصلاح عيب جوهري — التعديل على $ReportLines داخل الدوال كان يحدث
#   على نسخة محلية فقط، فكانت التقارير تُخرج فارغة (تكرار 3 مرات). الآن تُستخدم
#   قائمة على مستوى السكربت $script:ReportLines. وكذلك: التذييل يُكتب قبل الحفظ
#   (كان يُضاف بعد Save-Content فيضيع)، والمخرج في artifacts/ (متجاهَل من Git)،
#   وأُضيفت سعات البطارية من root\wmi (أدق من Win32_Battery في هذا الجهاز).
# =============================================================================

$script:ReportLines = [System.Collections.Generic.List[string]]::new()

$ArtifactsDir = Join-Path (Get-Location) 'artifacts'
if (-not (Test-Path $ArtifactsDir)) { New-Item -ItemType Directory -Force -Path $ArtifactsDir | Out-Null }
$OutputFile = Join-Path $ArtifactsDir ("hardware-discovery-report-{0}.txt" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Write-Report {
    param([string]$Message)
    $script:ReportLines.Add($Message)
}

function Write-Section {
    param([string]$Title)
    $script:ReportLines.Add("")
    $script:ReportLines.Add("=" * 80)
    $script:ReportLines.Add($Title)
    $script:ReportLines.Add("=" * 80)
    $script:ReportLines.Add("")
}

# --- Section 1: Boot Mode (UEFI vs Legacy BIOS) ---
Write-Section "1. وضع الإقلاع (Boot Mode)"

$isUEFI = $false
try {
    $firmwareType = [System.Environment]::GetEnvironmentVariable("FIRMWARE_TYPE")
    if ($firmwareType) {
        Write-Report "FIRMWARE_TYPE environment variable: $firmwareType"
        if ($firmwareType -eq "UEFI") { $isUEFI = $true }
    }
} catch {}

try {
    $bootMode = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Firmware" -Name "BootMode" -ErrorAction Stop
    Write-Report "BootMode (السجل): $($bootMode.BootMode)"
    if ($bootMode.BootMode -eq 1) { $isUEFI = $true }
} catch {
    Write-Report "لا يمكن قراءة BootMode من السجل (قد تحتاج صلاحيات Administrator)"
}

Write-Report "الاستنتاج المبدئي: UEFI=$isUEFI — يجب التأكيد يدوياً من شاشة BIOS"

# --- Section 2: Disk Partition Style (GPT vs MBR) ---
Write-Section "2. نمط تقسيم القرص (Disk Partition Style)"

try {
    $disks = Get-Disk | Select-Object Number, FriendlyName, Size, PartitionStyle, HealthStatus, OperationalStatus
    foreach ($disk in $disks) {
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        Write-Report "القرص رقم $($disk.Number): $($disk.FriendlyName)"
        Write-Report "  الحجم: $sizeGB GB"
        Write-Report "  نمط التقسيم: $($disk.PartitionStyle)"
        Write-Report "  الحالة: $($disk.HealthStatus) / $($disk.OperationalStatus)"
        Write-Report ""
    }
} catch {
    Write-Report "فشل في قراءة تقسيم الأقراص (قد تحتاج تشغيل PowerShell كمسؤول)"
}

# --- Section 3: Secure Boot ---
Write-Section "3. Secure Boot"

try {
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    Write-Report "Secure Boot: $sb"
} catch {
    Write-Report "لا يمكن قراءة حالة Secure Boot (قد يكون النظام في وضع Legacy BIOS، أو تحتاج صلاحيات Administrator)"
}

# --- Section 4: TPM ---
Write-Section "4. وحدة الأمان المعتمدة (TPM)"

try {
    $tpm = Get-Tpm -ErrorAction Stop
    Write-Report "موجود TPM: $($tpm.TpmPresent)"
    Write-Report "الإصدار: $($tpm.SpecificationVersion)"
    Write-Report "الحالة: $($tpm.Status)"
} catch {
    Write-Report "لا يمكن قراءة معلومات TPM (قد تحتاج صلاحيات Administrator، أو غير موجود)"
}

# --- Section 5: BitLocker ---
Write-Section "5. تشفير القرص (BitLocker)"

try {
    $bl = Get-BitLockerVolume -ErrorAction Stop
    foreach ($vol in $bl) {
        Write-Report "المحرف: $($vol.MountPoint) — حالة التشفير: $($vol.VolumeStatus) — طريقة التشفير: $($vol.EncryptionMethod)"
    }
} catch {
    Write-Report "لا يمكن قراءة حالة BitLocker (قد تحتاج صلاحيات Administrator، أو غير مفعّل)"
}

# --- Section 6: CPU Details ---
Write-Section "6. تفاصيل المعالج (CPU)"

try {
    $cpu = Get-WmiObject Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, CurrentClockSpeed, Architecture, ProcessorId
    foreach ($c in $cpu) {
        Write-Report "الاسم: $($c.Name)"
        Write-Report "عدد النوى الفعلية: $($c.NumberOfCores)"
        Write-Report "المعالجات المنطقية: $($c.NumberOfLogicalProcessors)"
        Write-Report "الحد الأقصى للتردد: $($c.MaxClockSpeed) MHz"
        Write-Report "التردد الحالي: $($c.CurrentClockSpeed) MHz"
        Write-Report "معرف المعالج: $($c.ProcessorId)"
    }
} catch {
    Write-Report "فشل في قراءة معلومات المعالج"
}

# --- Section 7: Memory (RAM) ---
Write-Section "7. الذاكرة العشوائية (RAM)"

try {
    $mem = Get-WmiObject Win32_PhysicalMemory | Select-Object Capacity, Speed, Manufacturer, PartNumber, MemoryType, DeviceLocator
    foreach ($m in $mem) {
        $capGB = [math]::Round([int64]$m.Capacity / 1GB, 2)
        Write-Report "السعة: $capGB GB"
        Write-Report "السرعة: $($m.Speed) MHz"
        Write-Report "الشركة المصنعة: $($m.Manufacturer)"
        Write-Report "رقم القطعة: $($m.PartNumber)"
        Write-Report "نوع الذاكرة (SMBIOS): $($m.MemoryType)"
        Write-Report "موقع الشريحة: $($m.DeviceLocator)"
        Write-Report ""
    }

    $sysMem = Get-WmiObject Win32_ComputerSystem | Select-Object TotalPhysicalMemory
    $totalGB = [math]::Round([int64]$sysMem.TotalPhysicalMemory / 1GB, 2)
    Write-Report "إجمالي الذاكرة الظاهرة للنظام: $totalGB GB"
} catch {
    Write-Report "فشل في قراءة معلومات الذاكرة"
}

# --- Section 8: Storage ---
Write-Section "8. محركات التخزين (Storage)"

try {
    $disks = Get-Disk | Select-Object Number, FriendlyName, Size, MediaType, BusType, PartitionStyle
    foreach ($d in $disks) {
        $sizeGB = [math]::Round($d.Size / 1GB, 2)
        Write-Report "القرص $($d.Number): $($d.FriendlyName)"
        Write-Report "  الحجم: $sizeGB GB"
        Write-Report "  نوع الوسيط: $($d.MediaType)"
        Write-Report "  نوع الناقل: $($d.BusType)"
        Write-Report "  نمط التقسيم: $($d.PartitionStyle)"
        Write-Report ""
    }

    $volumes = Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, Size, HealthStatus
    foreach ($v in $volumes) {
        if ($v.DriveLetter) {
            $sizeGB = [math]::Round($v.Size / 1GB, 2)
            Write-Report "المحرف $($v.DriveLetter): — التسمية: $($v.FileSystemLabel) — النظام: $($v.FileSystem) — الحجم: $sizeGB GB — الصحة: $($v.HealthStatus)"
        }
    }
} catch {
    Write-Report "فشل في قراءة معلومات التخزين"
}

# --- Section 9: Graphics (GPU) ---
Write-Section "9. كروت الشاشة (GPU)"

try {
    $gpus = Get-WmiObject Win32_VideoController | Select-Object Name, VideoProcessor, AdapterRAM, CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate, DriverVersion, DriverDate, VideoArchitecture, VideoMemoryType
    foreach ($g in $gpus) {
        $vramMB = [math]::Round([int64]$g.AdapterRAM / 1MB, 2)
        Write-Report "اسم GPU: $($g.Name)"
        Write-Report "معالج الفيديو: $($g.VideoProcessor)"
        Write-Report "ذاكرة الفيديو الظاهرة (AdapterRAM): $vramMB MB (ملاحظة: قد تشمل ذاكرة نظام مشتركة)"
        Write-Report "دقة العرض الحالية: $($g.CurrentHorizontalResolution) x $($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate) Hz"
        Write-Report "إصدار التعريف: $($g.DriverVersion) (تاريخ: $($g.DriverDate))"
        Write-Report "بنية الفيديو: $($g.VideoArchitecture)"
        Write-Report "نوع ذاكرة الفيديو: $($g.VideoMemoryType)"
        Write-Report ""
    }
} catch {
    Write-Report "فشل في قراءة معلومات كروت الشاشة"
}

# --- Section 10: Network ---
Write-Section "10. الشبكة (Network)"

try {
    $adapters = Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, LinkSpeed, MediaConnectionState
    foreach ($a in $adapters) {
        Write-Report "اسم المحول: $($a.Name)"
        Write-Report "الوصف: $($a.InterfaceDescription)"
        Write-Report "الحالة: $($a.Status)"
        Write-Report "سرعة الاتصال: $($a.LinkSpeed)"
        Write-Report "حالة الاتصال: $($a.MediaConnectionState)"
        Write-Report ""
    }
} catch {
    Write-Report "فشل في قراءة معلومات محولات الشبكة"
}

# --- Section 11: Audio ---
Write-Section "11. الصوت (Audio)"

try {
    $audio = Get-WmiObject Win32_SoundDevice | Select-Object Name, Manufacturer, Status, DeviceID
    foreach ($s in $audio) {
        Write-Report "جهاز الصوت: $($s.Name)"
        Write-Report "الشركة المصنعة: $($s.Manufacturer)"
        Write-Report "الحالة: $($s.Status)"
        Write-Report ""
    }
} catch {
    Write-Report "فشل في قراءة معلومات أجهزة الصوت"
}

# --- Section 12: Battery ---
Write-Section "12. البطارية (Battery)"

try {
    $bat = Get-WmiObject Win32_Battery | Select-Object Name, EstimatedChargeRemaining, BatteryStatus, Chemistry, DesignCapacity, FullChargeCapacity, DeviceID
    foreach ($b in $bat) {
        Write-Report "اسم البطارية: $($b.Name)"
        Write-Report "نسبة الشحن المتبقية: $($b.EstimatedChargeRemaining)%"
        Write-Report "حالة البطارية: $($b.BatteryStatus)"
        Write-Report "السعة التصميمية: $($b.DesignCapacity)"
        Write-Report "السعة الكاملة للشحن: $($b.FullChargeCapacity)"
        Write-Report ""
    }
} catch {
    Write-Report "فشل في قراءة معلومات البطارية الأساسية"
}

# قياس أدق من root\wmi (أثبت عمله في هذا الجهاز بتاريخ 2026-11-11)
try {
    $bs = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction Stop
    $fc = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction Stop
    Write-Report "السعة التصميمية (root\wmi BatteryStaticData): $($bs.DesignedCapacity) mWh"
    Write-Report "السعة الكاملة الفعلية (root\wmi BatteryFullChargedCapacity): $($fc.FullChargedCapacity) mWh"
    if ($bs.DesignedCapacity -and $fc.FullChargedCapacity) {
        $health = [math]::Round(100 * $fc.FullChargedCapacity / $bs.DesignedCapacity, 1)
        Write-Report "صحة البطارية التقديرية: $health%"
    }
} catch {
    Write-Report "لا يمكن قراءة سعات البطارية من root\wmi: $($_.Exception.Message)"
}

# --- Section 13: USB & Bluetooth ---
Write-Section "13. USB و Bluetooth"

try {
    $usb = Get-WmiObject Win32_USBController | Select-Object Name, Manufacturer, Status, DeviceID
    foreach ($u in $usb) {
        Write-Report "متحكم USB: $($u.Name) — الشركة: $($u.Manufacturer) — الحالة: $($u.Status)"
    }

    $bt = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -like "*Bluetooth*" } | Select-Object Name, Manufacturer, Status
    foreach ($b in $bt) {
        Write-Report "جهاز Bluetooth: $($b.Name) — الشركة: $($b.Manufacturer) — الحالة: $($b.Status)"
    }
} catch {
    Write-Report "فشل في قراءة معلومات USB/Bluetooth"
}

# --- Section 14: Camera, Keyboard, Mouse, Touchpad ---
Write-Section "14. أجهزة الإدخال والكاميرا"

try {
    $cam = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -like "*Camera*" -or $_.Name -like "*Webcam*" } | Select-Object Name, Manufacturer, Status
    foreach ($c in $cam) {
        Write-Report "كاميرا: $($c.Name) — الشركة: $($c.Manufacturer) — الحالة: $($c.Status)"
    }

    $kb = Get-WmiObject Win32_Keyboard | Select-Object Name, Layout, Description
    foreach ($k in $kb) {
        Write-Report "لوحة المفاتيح: $($k.Name) — التخطيط: $($k.Layout) — الوصف: $($k.Description)"
    }

    $mouse = Get-WmiObject Win32_PointingDevice | Select-Object Name, Manufacturer, Description
    foreach ($m in $mouse) {
        Write-Report "جهاز التوجيه (ماوس/لوحة لمس): $($m.Name) — الشركة: $($m.Manufacturer) — الوصف: $($m.Description)"
    }
} catch {
    Write-Report "فشل في قراءة أجهزة الإدخال والكاميرا"
}

# --- Section 15: Display ---
Write-Section "15. الشاشة (Display)"

try {
    $disp = Get-WmiObject Win32_DesktopMonitor | Select-Object Name, ScreenWidth, ScreenHeight, Manufacturer, MonitorType, ScreenResolution
    foreach ($d in $disp) {
        Write-Report "اسم الشاشة: $($d.Name)"
        Write-Report "العرض: $($d.ScreenWidth) × الارتفاع: $($d.ScreenHeight)"
        Write-Report "الشركة المصنعة: $($d.Manufacturer)"
        Write-Report "نوع الشاشة: $($d.MonitorType)"
        Write-Report "الدقة المسجلة: $($d.ScreenResolution)"
    }
} catch {
    Write-Report "فشل في قراءة معلومات الشاشة"
}

# --- Section 16: PCI Devices ---
Write-Section "16. أجهزة PCI (للتحقق من التوافق مع التعريفات)"

try {
    $pci = Get-WmiObject Win32_PnPEntity | Where-Object { $_.DeviceID -like "PCI*" } | Select-Object Name, Manufacturer, DeviceID, Status, DriverVersion
    foreach ($p in $pci) {
        Write-Report "الجهاز: $($p.Name) — معرف الجهاز: $($p.DeviceID) — الحالة: $($p.Status) — تعريف: $($p.DriverVersion)"
    }
} catch {
    Write-Report "فشل في قراءة أجهزة PCI"
}

# --- Section 17: Firmware / BIOS ---
Write-Section "17. البرنامج الثابت (BIOS/Firmware)"

try {
    $bios = Get-WmiObject Win32_BIOS | Select-Object Name, Manufacturer, Version, ReleaseDate, SMBIOSBIOSVersion
    foreach ($b in $bios) {
        Write-Report "الشركة المصنعة: $($b.Manufacturer)"
        Write-Report "الإصدار: $($b.Version)"
        Write-Report "تاريخ الإصدار: $($b.ReleaseDate)"
        Write-Report "إصدار SMBIOS: $($b.SMBIOSBIOSVersion)"
    }
} catch {
    Write-Report "فشل في قراءة معلومات BIOS"
}

# --- Section 18: Power & Thermal ---
Write-Section "18. الطاقة والحرارة"

try {
    $ps = Get-CimInstance Win32_ComputerSystem | Select-Object PowerManagementSupported, PCSystemType
    Write-Report "إدارة الطاقة مدعومة (PCSystemType: $($ps.PCSystemType))"
} catch {
    Write-Report "فشل في قراءة إمكانيات إدارة الطاقة"
}

# --- Footer (يُكتب قبل الحفظ) ---
Write-Report ""
Write-Section "نهاية التقرير"
Write-Report "تم حفظ التقرير في: $OutputFile"
Write-Report "تاريخ الإنشاء: $(Get-Date)"

# --- Save Report ---
$ReportContent = $script:ReportLines -join "`r`n"
Set-Content -Path $OutputFile -Value $ReportContent -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  تم الانتهاء من اكتشاف العتاد!" -ForegroundColor Green
Write-Host "  التقرير محفوظ في: $OutputFile" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
