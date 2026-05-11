# 🖴 disk-automount

سكريبت Bash احترافي يكتشف جميع الأقراص والأقسام تلقائيًا،
يركّبها، ويحفظها في `/etc/fstab` لتبقى دائمة عند كل إعادة تشغيل.

A professional Bash script that automatically detects all disks and partitions,
mounts them, and saves them to `/etc/fstab` for persistence across reboots.

---

## ✨ المميزات | Features

- 🔍 اكتشاف تلقائي لجميع الأقسام عبر `lsblk` + `blkid`
- 📦 تثبيت الحزم المطلوبة تلقائيًا (ntfs-3g, exfatprogs...)
- 💾 يدعم: `ext4` `btrfs` `xfs` `ntfs` `ntfs3` `exfat` `vfat` `f2fs`
- 🛡️ يتجاهل أقسام النظام (`/`, `/boot`, `swap`, EFI)
- 💡 يفضّل `ntfs3` (kernel driver) على `ntfs-3g` تلقائيًا
- 🔁 يدعم مديري الحزم: `pacman` `apt` `dnf` `zypper`
- 📋 نسخة احتياطية تلقائية من `/etc/fstab` قبل أي تعديل
- ⚠️ يضيف `nofail` لكل قسم لضمان الإقلاع الآمن

---

- 🔍 Auto-detects all partitions via `lsblk` + `blkid`
- 📦 Automatically installs required packages (ntfs-3g, exfatprogs...)
- 💾 Supports: `ext4` `btrfs` `xfs` `ntfs` `ntfs3` `exfat` `vfat` `f2fs`
- 🛡️ Skips system partitions (`/`, `/boot`, `swap`, EFI)
- 💡 Prefers `ntfs3` (kernel driver) over `ntfs-3g` automatically
- 🔁 Supports package managers: `pacman` `apt` `dnf` `zypper`
- 📋 Auto-backup of `/etc/fstab` before any modification
- ⚠️ Adds `nofail` to every entry for safe boot guarantee

---

## 🚀 الاستخدام | Usage

```bash
chmod +x disk-automount.sh
sudo bash disk-automount.sh
```

---

## ⚠️ مهم — قبل الاستخدام (مستخدمو Windows) | Important — Before Use (Windows Users)

إذا كنت تستخدم **Dual Boot** مع Windows، يجب **تعطيل Fast Startup و Hibernate** أولاً،
وإلا ستظل أقراص NTFS للقراءة فقط ولا تستطيع الحذف أو الكتابة.

If you use **Dual Boot** with Windows, you must **disable Fast Startup & Hibernate** first,
otherwise NTFS drives will be read-only and you won't be able to write or delete files.

### 🪟 تعطيل Fast Startup في Windows | Disable Fast Startup on Windows

**الطريقة الأولى — لوحة التحكم:**

1. افتح **Control Panel**
2. ادخل على: **Hardware and Sound → Power Options**
3. من اليسار اختر: **Choose what the power buttons do**
4. اضغط: **Change settings that are currently unavailable**
5. تحت قسم **Shutdown settings** شِل الصح من:
   **Turn on fast startup (recommended)**
6. اضغط **Save changes**

**الطريقة الثانية — موجه الأوامر (كمسؤول):**

```cmd
powercfg /h off
```

> 💡 بعد التعطيل، نفّذ **Shutdown كامل** (وليس Restart) ثم أقلع للينكس.
> Full Shutdown is required after disabling — do not use Restart.

---

## 🖥️ التوزيعات المدعومة | Supported Distros

| التوزيعة | Distro | مدير الحزم | Package Manager |
|---|---|---|---|
| Arch / Manjaro | Arch / Manjaro | pacman | pacman |
| Ubuntu / Debian | Ubuntu / Debian | apt | apt |
| Fedora / RHEL | Fedora / RHEL | dnf | dnf |
| openSUSE | openSUSE | zypper | zypper |

---

## ⚡ بعد التشغيل | After Running

```bash
# تركيب الكل | Mount all
sudo mount -a

# عرض الأقراص | List disks
lsblk -o NAME,MOUNTPOINT,FSTYPE,LABEL

# تأكد أن الأقراص مركّبة بصلاحية كتابة
mount | grep ntfs
```

---

## 🛠️ إذا بقي NTFS للقراءة فقط | If NTFS is Still Read-Only

```bash
# فك التركيب أولاً
sudo umount /dev/sdXn

# إصلاح dirty bit
sudo ntfsfix /dev/sdXn

# إعادة التركيب
sudo mount -a
```

---

## 📄 الترخيص | License

حقوق النشر محفوظة © 2026 — مُرخَّص بموجب رخصة MIT

Copyright © 2026 — Licensed under the MIT License
