#!/bin/bash
#========================================================
#  Auto GRUB Repair Script
#  Author: Andrew
#  License: MIT
#  Description: Automatically mounts partitions and reinstalls GRUB
#  Supports: Arch, EndeavourOS, Debian, Ubuntu, Fedora
#  Usage: Run from a live environment when the motherboard
#         does not recognize the bootloader
#========================================================

set -e

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# ASCII Banner
echo -e "${CYAN}"
cat << "EOF"
   ____ ____  _    _ ____  _   _ 
  / ___|  _ \| |  | | __ )| | | |
 | |  _| |_) | |  | |  _ \| | | |
 | |_| |  _ <| |__| | |_) | |_| |
  \____|_| \_\\____/|____/ \___/ 
                                 
EOF
echo -e "${RESET}"
echo -e "${YELLOW}=== Auto GRUB Repair Script ===${RESET}"

# Function to detect distro
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo -e "${RED}Cannot detect your distribution.${RESET}"
        exit 1
    fi
    echo -e "${GREEN}Detected distribution:${RESET} $DISTRO"
}

# Function to mount partitions
mount_partitions() {
    read -rp "Enter your root partition (e.g., /dev/sda2): " ROOT_PART
    read -rp "Enter your EFI partition (e.g., /dev/sda1): " EFI_PART

    echo -e "${CYAN}Mounting partitions...${RESET}"
    sudo mount "$ROOT_PART" /mnt
    sudo mount "$EFI_PART" /mnt/boot/efi
}

# Function to repair GRUB
repair_grub() {
    case "$DISTRO" in
        arch|endeavouros)
            echo -e "${YELLOW}Running Arch/EndeavourOS GRUB repair...${RESET}"
            sudo arch-chroot /mnt /bin/bash -c "
                grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
                grub-mkconfig -o /boot/grub/grub.cfg
            "
            ;;
        debian|ubuntu)
            echo -e "${YELLOW}Running Debian/Ubuntu GRUB repair...${RESET}"
            sudo chroot /mnt /bin/bash -c "
                grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
                update-grub
            "
            ;;
        fedora)
            echo -e "${YELLOW}Running Fedora GRUB repair...${RESET}"
            sudo chroot /mnt /bin/bash -c "
                grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
                grub2-mkconfig -o /boot/grub2/grub.cfg
            "
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${RESET}"
            exit 1
            ;;
    esac
}

# Function to finish with style
finish_message() {
    echo -e "${GREEN}"
    cat << "EOF"
  ____   ___  _   _ _____ _   _ 
 |  _ \ / _ \| | | | ____| \ | |
 | | | | | | | | | |  _| |  \| |
 | |_| | |_| | |_| | |___| |\  |
 |____/ \___/ \___/|_____|_| \_|
                                
EOF
    echo -e "${RESET}${CYAN}Done: GRUB repaired in liveuser mode for cases where the motherboard does not recognize the bootloader.${RESET}"
}

# Main call sequence
detect_distro
mount_partitions
repair_grub
finish_message
