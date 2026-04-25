# 🖴 disk-automount

سكريبت Bash احترافي يكتشف جميع الأقراص والأقسام تلقائيًا،
يركّبها، ويحفظها في `/etc/fstab` لتبقى دائمة عند كل إعادة تشغيل.

## ✨ المميزات

- 🔍 اكتشاف تلقائي لجميع الأقسام عبر `lsblk` + `blkid`
- 📦 تثبيت الحزم المطلوبة تلقائيًا (ntfs-3g, exfatprogs...)
- 💾 يدعم: `ext4` `btrfs` `xfs` `ntfs` `ntfs3` `exfat` `vfat` `f2fs`
- 🛡️ يتجاهل أقسام النظام (`/`, `/boot`, `swap`, EFI)
- 💡 يفضّل `ntfs3` (kernel driver) على `ntfs-3g` تلقائيًا
- 🔁 يدعم مديري الحزم: `pacman` `apt` `dnf` `zypper`
- 📋 نسخة احتياطية تلقائية من `/etc/fstab` قبل أي تعديل
- ⚠️ يضيف `nofail` لكل قسم لضمان الإقلاع الآمن

## 🚀 الاستخدام

```bash
chmod +x disk-automount.sh
sudo bash disk-automount.sh
```

## 🖥️ التوزيعات المدعومة

| التوزيعة | مدير الحزم |
|---|---|
| Arch / Manjaro | pacman |
| Ubuntu / Debian | apt |
| Fedora / RHEL | dnf |
| openSUSE | zypper |

## ⚡ بعد التشغيل

```bash
sudo mount -a
lsblk -o NAME,MOUNTPOINT,FSTYPE,LABEL
```

## 📄 الترخيص

MIT License
