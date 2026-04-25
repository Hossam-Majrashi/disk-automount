# 🖴 disk-automount

سكريبت Bash احترافي يكتشف جميع الأقراص والأقسام تلقائيًا،
يركّبها، ويحفظها في `/etc/fstab` لتبقى دائمة عند كل إعادة تشغيل.

A professional Bash script that automatically detects all disks and partitions,
mounts them, and saves them to `/etc/fstab` for persistence across reboots.

***

## ✨ المميزات | Features

- 🔍 اكتشاف تلقائي لجميع الأقسام عبر `lsblk` + `blkid`
- 📦 تثبيت الحزم المطلوبة تلقائيًا (ntfs-3g, exfatprogs...)
- 💾 يدعم: `ext4` `btrfs` `xfs` `ntfs` `ntfs3` `exfat` `vfat` `f2fs`
- 🛡️ يتجاهل أقسام النظام (`/`, `/boot`, `swap`, EFI)
- 💡 يفضّل `ntfs3` (kernel driver) على `ntfs-3g` تلقائيًا
- 🔁 يدعم مديري الحزم: `pacman` `apt` `dnf` `zypper`
- 📋 نسخة احتياطية تلقائية من `/etc/fstab` قبل أي تعديل
- ⚠️ يضيف `nofail` لكل قسم لضمان الإقلاع الآمن

***

- 🔍 Auto-detects all partitions via `lsblk` + `blkid`
- 📦 Automatically installs required packages (ntfs-3g, exfatprogs...)
- 💾 Supports: `ext4` `btrfs` `xfs` `ntfs` `ntfs3` `exfat` `vfat` `f2fs`
- 🛡️ Skips system partitions (`/`, `/boot`, `swap`, EFI)
- 💡 Prefers `ntfs3` (kernel driver) over `ntfs-3g` automatically
- 🔁 Supports package managers: `pacman` `apt` `dnf` `zypper`
- 📋 Auto-backup of `/etc/fstab` before any modification
- ⚠️ Adds `nofail` to every entry for safe boot guarantee

***

## 🚀 الاستخدام | Usage

```bash
chmod +x disk-automount.sh
sudo bash disk-automount.sh
```

***

## 🖥️ التوزيعات المدعومة | Supported Distros

| التوزيعة | Distro | مدير الحزم | Package Manager |
|---|---|---|---|
| Arch / Manjaro | Arch / Manjaro | pacman | pacman |
| Ubuntu / Debian | Ubuntu / Debian | apt | apt |
| Fedora / RHEL | Fedora / RHEL | dnf | dnf |
| openSUSE | openSUSE | zypper | zypper |

***

## ⚡ بعد التشغيل | After Running

```bash
# تركيب الكل | Mount all
sudo mount -a

# عرض الأقراص | List disks
lsblk -o NAME,MOUNTPOINT,FSTYPE,LABEL
```

***

## 📄 الترخيص | License

حقوق النشر محفوظة © 2026 — مُرخَّص بموجب رخصة MIT

Copyright © 2026 — Licensed under the MIT License

```
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```
