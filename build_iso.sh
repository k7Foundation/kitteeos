#!/bin/bash
set -e

WORKSPACE="/workspaces/kitteeos"
CHROOT_DIR="${WORKSPACE}/work/work/chroot"
ISO_DIR="${WORKSPACE}/iso_build/CD"
ISO_NAME="kitteeos-live-amd64.iso"

echo "--> Ставим утилиты..."
sudo apt-get update && sudo apt-get install -y squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools

echo "--> Чистим старое..."
sudo rm -rf "${WORKSPACE}/iso_build"
mkdir -p "${ISO_DIR}/live" "${ISO_DIR}/boot/grub"

echo "--> Пакуем систему (SquashFS)..."
sudo mksquashfs "${CHROOT_DIR}" "${ISO_DIR}/live/filesystem.squashfs" -noappend -comp xz -e boot proc sys dev run tmp

echo "--> Копируем ядро..."
cp $(ls -v ${CHROOT_DIR}/boot/vmlinuz-* | tail -n 1) "${ISO_DIR}/live/vmlinuz"
cp $(ls -v ${CHROOT_DIR}/boot/initrd.img-* | tail -n 1) "${ISO_DIR}/live/initrd"

echo "--> Настраиваем GRUB..."
cat <<'G' > "${ISO_DIR}/boot/grub/grub.cfg"
set timeout=5
menuentry "KitteeOS Live" {
    linux /live/vmlinuz boot=live quiet splash ---
    initrd /live/initrd
}
G

echo "--> Собираем ISO..."
sudo grub-mkrescue -o "${WORKSPACE}/${ISO_NAME}" "${ISO_DIR}"
echo "Готово: ${WORKSPACE}/${ISO_NAME}"