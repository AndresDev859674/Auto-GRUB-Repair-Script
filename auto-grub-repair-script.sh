#!/bin/bash
# Auto GRUB Repair Script
# Author: Andrew
# License: MIT
# Description: Automatically mounts partitions and reinstalls GRUB
# Supports: Arch, EndeavourOS, Debian, Ubuntu, Fedora
# Usage: Run from a live environment when the motherboard does not recognize the bootloader

set -e

echo "=== Auto GRUB Repair Script ==="

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect your distribution."
    exit 1
fi

echo "Detected distribution: $DISTRO"

# Ask for partitions
read -rp "Enter your root partition (e.g., /dev/sda2): " ROOT_PART
read -rp "Enter your EFI partition (e.g., /dev/sda1): " EFI_PART

# Mount partitions
echo "Mounting partitions..."
sudo mount "$ROOT_PART" /mnt
sudo mount "$EFI_PART" /mnt/boot/efi

# Chroot and run GRUB commands based on distro
case "$DISTRO" in
    arch|endeavouros)
        echo "Running Arch/EndeavourOS GRUB repair..."
        sudo arch-chroot /mnt /bin/bash -c "
            grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
            grub-mkconfig -o /boot/grub/grub.cfg
        "
        ;;
    debian|ubuntu)
        echo "Running Debian/Ubuntu GRUB repair..."
        sudo chroot /mnt /bin/bash -c "
            grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
            update-grub
        "
        ;;
    fedora)
        echo "Running Fedora GRUB repair..."
        sudo chroot /mnt /bin/bash -c "
            grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
            grub2-mkconfig -o /boot/grub2/grub.cfg
        "
        ;;
    *)
        echo "Unsupported distribution: $DISTRO"
        exit 1
        ;;
esac

echo "=== Done: GRUB repaired in liveuser mode for cases where the motherboard does not recognize the bootloader ==="
