#!/bin/bash
set -e

# Конфигурация путей
WORKSPACE="/workspaces/kitteeos"
CHROOT_DIR="${WORKSPACE}/work/work/chroot"
BUILD_DIR="${WORKSPACE}/iso_build"
ISO_DIR="${BUILD_DIR}/CD"
ISO_NAME="kitteeos-live-amd64.iso"

echo "=== Сборщик ISO-образов KitteeOS ==="
echo "Путь к chroot: ${CHROOT_DIR}"
echo "Временная папка сборки: ${BUILD_DIR}"

# 1. Установка необходимых инструментов сборки на хост-машину Codespaces
echo "--> Установка утилит сборки (squashfs, xorriso, grub)..."
sudo apt-get update && sudo apt-get install -y squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools sgabios

# 2. Очистка старых файлов сборки
echo "--> Очистка временных файлов..."
sudo rm -rf "${BUILD_DIR}"
mkdir -p "${ISO_DIR}/live"
mkdir -p "${ISO_DIR}/boot/grub"

# 3. Сжатие нашей системы в SquashFS (основной сжатый образ ОС)
echo "--> Сжатие системы KitteeOS в SquashFS (это займет пару минут)..."
sudo mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/live/filesystem.squashfs" -noappend -e boot

# 4. Копирование Ядра (vmlinuz) и Initrd из chroot в наш ISO
echo "--> Копирование ядра и initramfs..."
KERNEL=$(ls -v ${CHROOT_DIR}/boot/vmlinuz-* | tail -n 1)
INITRD=$(ls -v ${CHROOT_DIR}/boot/initrd.img-* | tail -n 1)

if [ -z "$KERNEL" ] || [ -z "$INITRD" ]; then
    echo "ОШИБКА: Ядро или initrd не найдены в ${CHROOT_DIR}/boot!"
    echo "Убедись, что внутри chroot установлен пакет linux-image-generic."
    exit 1
fi

cp "$KERNEL" "${ISO_DIR}/live/vmlinuz"
cp "$INITRD" "${ISO_DIR}/live/initrd"

# 5. Создание конфигурации загрузчика GRUB
echo "--> Создание меню загрузки GRUB..."
cat <<'GRUB_CONF' > "${ISO_DIR}/boot/grub/grub.cfg"
set default="0"
set timeout=10

menuentry "KitteeOS Live (Wayland/LXQt/LibreWolf)" {
    linux /live/vmlinuz boot=live quiet splash ---
    initrd /live/initrd
}

menuentry "KitteeOS Live (Safe Graphics Mode)" {
    linux /live/vmlinuz boot=live nomodeset quiet splash ---
    initrd /live/initrd
}
GRUB_CONF

# 6. Сборка финального ISO
echo "--> Генерация загрузочного ISO-образа..."
sudo grub-mkrescue -o "${WORKSPACE}/${ISO_NAME}" "${ISO_DIR}"

echo "========================================="
echo " УСПЕХ: Образ KitteeOS успешно собран!"
echo " Файл: ${WORKSPACE}/${ISO_NAME}"
echo " Размер: $(du -sh ${WORKSPACE}/${ISO_NAME} | cut -f1)"
echo "========================================="
