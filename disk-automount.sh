#!/bin/bash

# ================================================================
#  disk-automount.sh — تركيب الأقراص تلقائيًا وحفظها في /etc/fstab
#  الإصدار: 2.0 | يدعم: ext4, btrfs, xfs, ntfs, exfat, vfat, f2fs
# ================================================================

set -uo pipefail

# ─── ألوان الطرفية ────────────────────────────────────────────
RED='\033[0;31m';   GREEN='\033[0;32m';  YELLOW='\033[1;33m'
BLUE='\033[0;34m';  CYAN='\033[0;36m';   BOLD='\033[1m';  NC='\033[0m'

log_info()    { echo -e "${CYAN}ℹ  $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_error()   { echo -e "${RED}❌ $*${NC}"; }

# ─── التحقق من صلاحيات root ──────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "يجب تشغيل السكريبت بصلاحيات root"
        echo -e "  ${BOLD}الحل:${NC} sudo bash $0"
        exit 1
    fi
}

# ─── تحديد مدير الحزم ────────────────────────────────────────
detect_pkg_manager() {
    if   command -v pacman  &>/dev/null; then echo "pacman"
    elif command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf     &>/dev/null; then echo "dnf"
    elif command -v zypper  &>/dev/null; then echo "zypper"
    else echo "unknown"
    fi
}

# ─── تثبيت حزمة واحدة ────────────────────────────────────────
install_pkg() {
    local pkg="$1"
    local mgr
    mgr=$(detect_pkg_manager)

    log_info "تثبيت: $pkg"
    case "$mgr" in
        pacman) pacman -Sy --noconfirm "$pkg" &>/dev/null ;;
        apt)    apt-get install -y -qq "$pkg" &>/dev/null ;;
        dnf)    dnf install -y -q "$pkg"      &>/dev/null ;;
        zypper) zypper install -y "$pkg"       &>/dev/null ;;
        *)
            log_warn "مدير الحزم غير معروف — ثبّت $pkg يدويًا"
            return 1
            ;;
    esac
}

# ─── التحقق من الحزم المطلوبة وتثبيتها ──────────────────────
install_deps() {
    echo -e "\n${BOLD}${BLUE}── التحقق من الحزم المطلوبة ──────────────────────────────${NC}"

    # blkid و lsblk يأتيان مع util-linux (مثبّت مسبقًا في معظم التوزيعات)
    if ! command -v blkid &>/dev/null || ! command -v lsblk &>/dev/null; then
        install_pkg "util-linux" && log_success "util-linux مثبّت" || log_error "فشل تثبيت util-linux"
    else
        log_success "util-linux متوفر"
    fi

    # دعم NTFS — نفضّل ntfs3 (kernel built-in) ثم ntfs-3g
    if ! grep -q ntfs3 /proc/filesystems 2>/dev/null; then
        if ! command -v mount.ntfs-3g &>/dev/null && ! command -v ntfs-3g &>/dev/null; then
            install_pkg "ntfs-3g" && log_success "ntfs-3g مثبّت" || log_warn "تعذّر تثبيت ntfs-3g"
        else
            log_success "دعم NTFS متوفر (ntfs-3g)"
        fi
    else
        log_success "دعم NTFS متوفر (ntfs3 kernel)"
    fi

    # دعم exFAT
    local exfat_ok=false
    command -v mkfs.exfat &>/dev/null && exfat_ok=true
    command -v exfatfsck  &>/dev/null && exfat_ok=true
    grep -q exfat /proc/filesystems 2>/dev/null && exfat_ok=true

    if ! $exfat_ok; then
        local mgr
        mgr=$(detect_pkg_manager)
        case "$mgr" in
            pacman) install_pkg "exfatprogs" ;;
            apt)    install_pkg "exfat-fuse" || install_pkg "exfatprogs" ;;
            dnf)    install_pkg "exfatprogs" ;;
            *)      install_pkg "exfatprogs" ;;
        esac
        log_success "دعم exFAT مثبّت" 2>/dev/null || log_warn "تعذّر تثبيت دعم exFAT"
    else
        log_success "دعم exFAT متوفر"
    fi
}

# ─── نسخة احتياطية من fstab ──────────────────────────────────
backup_fstab() {
    local backup="/etc/fstab.bak.$(date +%Y%m%d_%H%M%S)"
    if cp /etc/fstab "$backup" 2>/dev/null; then
        log_info "نسخة احتياطية محفوظة: $backup"
    else
        log_warn "تعذّر إنشاء نسخة احتياطية من fstab"
    fi
}

# ─── هل القسم قسم نظام يجب تجاهله؟ ─────────────────────────
is_system_partition() {
    local device="$1"
    local fstype="$2"

    # تجاهل swap دائمًا
    [[ "$fstype" == "swap" ]] && return 0

    # تجاهل أقراص EFI (vfat مع label خاص)
    if [[ "$fstype" == "vfat" ]]; then
        local label
        label=$(blkid -s LABEL -o value "$device" 2>/dev/null || true)
        [[ "$label" =~ ^(EFI|esp|ESP|BOOT|boot)$ ]] && return 0
    fi

    # تجاهل إذا كان مركّبًا على مسار نظام حساس
    local current_mount
    current_mount=$(findmnt -rn -o TARGET -S "$device" 2>/dev/null || true)
    if [[ -n "$current_mount" ]]; then
        case "$current_mount" in
            /|/boot|/boot/efi|/efi|/home|/var|/usr|/tmp|/opt|/srv)
                return 0 ;;
        esac
    fi

    return 1
}

# ─── خيارات التركيب المناسبة لكل نظام ملفات ─────────────────
get_mount_opts() {
    local fstype="$1"
    case "$fstype" in
        ntfs|ntfs3|ntfs-3g)
            echo "defaults,uid=1000,gid=1000,umask=022,nofail"
            ;;
        vfat|exfat)
            echo "defaults,uid=1000,gid=1000,umask=022,nofail"
            ;;
        ext4|ext3|ext2)
            echo "defaults,noatime,nofail"
            ;;
        btrfs)
            echo "defaults,noatime,compress=zstd,nofail"
            ;;
        xfs)
            echo "defaults,noatime,nofail"
            ;;
        f2fs)
            echo "defaults,noatime,nofail"
            ;;
        *)
            echo "defaults,nofail"
            ;;
    esac
}

# ─── تحديد driver التركيب ─────────────────────────────────────
get_mount_type() {
    local fstype="$1"
    case "$fstype" in
        ntfs)
            if grep -q "^ntfs3$" /proc/filesystems 2>/dev/null; then
                echo "ntfs3"
            elif command -v ntfs-3g &>/dev/null || command -v mount.ntfs-3g &>/dev/null; then
                echo "ntfs-3g"
            else
                echo "ntfs"
            fi
            ;;
        *) echo "$fstype" ;;
    esac
}

# ─── إنشاء اسم آمن لنقطة التركيب ─────────────────────────────
make_mountpoint_name() {
    local label="$1"
    local device="$2"

    local name
    if [[ -n "$label" ]]; then
        name=$(echo "$label" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    else
        name=$(basename "$device")
    fi

    echo "/mnt/${name}"
}

# ─── تركيب قسم واحد ──────────────────────────────────────────
mount_partition() {
    local device="$1"
    local mountpoint="$2"
    local fstype="$3"
    local opts="$4"

    # إذا كان مركّبًا بالفعل
    if findmnt -rn -o SOURCE "$mountpoint" 2>/dev/null | grep -q "$device"; then
        log_warn "مركّب مسبقًا: $device → $mountpoint"
        return 0
    fi

    # إذا كانت نقطة التركيب مشغولة
    if mountpoint -q "$mountpoint" 2>/dev/null; then
        return 1
    fi

    mkdir -p "$mountpoint"

    # محاولة التركيب بالخيارات الكاملة
    if mount -t "$fstype" -o "$opts" "$device" "$mountpoint" 2>/dev/null; then
        return 0
    fi

    # محاولة بخيارات مبسّطة
    if mount -t "$fstype" "$device" "$mountpoint" 2>/dev/null; then
        log_warn "تم التركيب بخيارات افتراضية"
        return 0
    fi

    # محاولة بنوع تلقائي
    if mount "$device" "$mountpoint" 2>/dev/null; then
        log_warn "تم التركيب بنوع تلقائي (auto)"
        return 0
    fi

    return 1
}

# ═══════════════════════════════════════════════════════════════
#  البرنامج الرئيسي
# ═══════════════════════════════════════════════════════════════
main() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║     🖴  مُركِّب الأقراص التلقائي  v2.0            ║"
    echo "║     Auto Disk Mounter + fstab Persistence       ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_root
    install_deps
    backup_fstab

    echo -e "\n${BOLD}${BLUE}── فحص الأقسام ──────────────────────────────────────────${NC}"

    local total=0 added=0 skipped=0 failed=0 already=0

    # قراءة جميع الأقسام (نوع part أو lvm) من lsblk
    while IFS= read -r device; do
        [[ -z "$device" ]] && continue

        local uuid fstype label
        uuid=$(blkid   -s UUID  -o value "$device" 2>/dev/null || true)
        fstype=$(blkid -s TYPE  -o value "$device" 2>/dev/null || true)
        label=$(blkid  -s LABEL -o value "$device" 2>/dev/null || true)

        # تجاهل إذا لا يوجد UUID أو نوع
        [[ -z "$uuid" || -z "$fstype" ]] && continue

        # تجاهل أقسام النظام
        if is_system_partition "$device" "$fstype"; then
            log_warn "تجاهل (قسم نظام): $device ($fstype)"
            ((skipped++))
            continue
        fi

        ((total++))

        echo -e "\n${BOLD}  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        printf  "  ${BOLD}%-14s${NC} %s\n" "📀 الجهاز:"  "$device"
        printf  "  ${BOLD}%-14s${NC} %s\n" "📦 النوع:"   "$fstype"
        printf  "  ${BOLD}%-14s${NC} %s\n" "🏷  الاسم:"   "${label:-—}"
        printf  "  ${BOLD}%-14s${NC} %s\n" "🆔 UUID:"    "$uuid"

        # ─── فحص fstab مسبقًا ──────────────────────────────
        if grep -q "UUID=$uuid" /etc/fstab 2>/dev/null; then
            log_warn "موجود مسبقًا في /etc/fstab — تخطي"
            ((already++))
            continue
        fi

        # ─── نقطة التركيب ──────────────────────────────────
        local mountpoint
        mountpoint=$(make_mountpoint_name "$label" "$device")

        # تجنّب التعارض في الأسماء
        local suffix=0
        local base_mp="$mountpoint"
        while [[ -d "$mountpoint" ]] && mountpoint -q "$mountpoint" 2>/dev/null; do
            ((suffix++))
            mountpoint="${base_mp}_${suffix}"
        done

        printf  "  ${BOLD}%-14s${NC} %s\n" "📁 المونت:" "$mountpoint"

        # ─── التركيب ───────────────────────────────────────
        local mount_type mount_opts
        mount_type=$(get_mount_type "$fstype")
        mount_opts=$(get_mount_opts  "$fstype")

        local mount_ok=true
        if ! mount_partition "$device" "$mountpoint" "$mount_type" "$mount_opts"; then
            log_error "فشل التركيب: $device"
            ((failed++))
            mount_ok=false
        else
            log_success "تم التركيب"
        fi

        # ─── الإضافة إلى /etc/fstab دائمًا ────────────────
        # pass=2 للـ ext4/btrfs/xfs | pass=0 لـ ntfs/fat/exfat (لا يدعم fsck)
        local pass=2
        [[ "$fstype" =~ ^(ntfs|ntfs3|ntfs-3g|vfat|exfat|f2fs)$ ]] && pass=0

        {
            printf "# %s — أُضيف بواسطة disk-automount.sh — %s\n" "${label:-$(basename "$device")}" "$(date '+%Y-%m-%d %H:%M')"
            printf "UUID=%s\t%s\t%s\t%s\t0\t%d\n" "$uuid" "$mountpoint" "$mount_type" "$mount_opts" "$pass"
        } >> /etc/fstab

        log_success "تم الإضافة إلى /etc/fstab"
        echo -e "  ${CYAN}📝 UUID=$uuid → $mountpoint ($mount_type)${NC}"
        ((added++))

    done < <(lsblk -rn -o PATH,TYPE 2>/dev/null \
             | awk '$2 == "part" || $2 == "lvm" {print $1}' \
             | sort -u)

    # ─── إعادة تحميل systemd ──────────────────────────────
    if command -v systemctl &>/dev/null; then
        systemctl daemon-reload 2>/dev/null && log_success "تم تحديث systemd" || true
    fi

    # ─── الملخص ────────────────────────────────────────────
    echo -e "\n${BOLD}${BLUE}"
    echo "╔══════════════════════════════════════════════════╗"
    echo "║                   📊 الملخص                     ║"
    echo "╠══════════════════════════════════════════════════╣"
    printf "║  🔍 أقسام مفحوصة:           %-20s║\n" "$total"
    printf "║  ✅ مُضافة لـ fstab:         %-20s║\n" "$added"
    printf "║  ⚠️  موجودة مسبقًا في fstab: %-20s║\n" "$already"
    printf "║  ⏭  مُتجاهلة (أقسام نظام):  %-20s║\n" "$skipped"
    printf "║  ❌ فشل التركيب (nofail):    %-20s║\n" "$failed"
    echo "╚══════════════════════════════════════════════════╝"
    echo -e "${NC}"

    if [[ $added -gt 0 ]]; then
        echo -e "${GREEN}${BOLD}🎉 الأقراص ستُركَّب تلقائيًا عند كل إعادة تشغيل!${NC}"
        echo ""
        echo -e "${CYAN}💡 أوامر مفيدة بعد التشغيل:"
        echo -e "   sudo mount -a                              # تركيب الكل الآن"
        echo -e "   lsblk -o NAME,MOUNTPOINT,FSTYPE,LABEL,UUID  # عرض الأقراص"
        echo -e "   cat /etc/fstab                              # عرض الإعدادات${NC}"
    else
        echo -e "${YELLOW}⚠️  لم تُضَف أقسام جديدة.${NC}"
    fi
    echo ""
}

main "$@"
