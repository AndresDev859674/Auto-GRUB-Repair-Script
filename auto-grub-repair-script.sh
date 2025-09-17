#!/bin/bash
#========================================================
#  GRUB Repair Ultimate
#  Author: Andrew
#  License: MIT
#  Description: Multi-distro GRUB repair tool for live environments
#  Supports: Arch, EndeavourOS, Debian, Ubuntu, Fedora, openSUSE, NixOS, CachyOS
#  Usage: Run from a live environment when the motherboard
#         does not recognize the bootloader
#========================================================

set -e
START_TIME=$(date +%s)

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
echo -e "${YELLOW}=== GRUB Repair Ultimate ===${RESET}"

# Show system info
echo -e "${CYAN}Gathering system information...${RESET}"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
if command -v dmidecode &>/dev/null; then
    echo "Motherboard: $(sudo dmidecode -s baseboard-manufacturer) $(sudo dmidecode -s baseboard-product-name)"
fi
echo "-----------------------------------"

# Detect distro
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

# Select boot mode
select_boot_mode() {
    echo -e "${CYAN}Select boot mode:${RESET}"
    echo "1) UEFI (recommended)"
    echo "2) BIOS (Legacy)"
    read -rp "Choice [1/2]: " BOOT_MODE
    if [ "$BOOT_MODE" != "1" ] && [ "$BOOT_MODE" != "2" ]; then
        echo -e "${RED}Invalid choice. Defaulting to UEFI.${RESET}"
        BOOT_MODE=1
    fi
}

# Confirm repair
confirm_repair() {
    echo -e "${YELLOW}WARNING:${RESET} This will modify your bootloader."
    read -rp "Do you want to proceed? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operation cancelled.${RESET}"
        exit 0
    fi
}

# Mount partitions
mount_partitions() {
    read -rp "Enter your root partition (e.g., /dev/sda2): " ROOT_PART
    if [ "$BOOT_MODE" = "1" ]; then
        read -rp "Enter your EFI partition (e.g., /dev/sda1): " EFI_PART
    fi

    echo -e "${CYAN}Mounting partitions...${RESET}"
    sudo mount "$ROOT_PART" /mnt
    if [ "$BOOT_MODE" = "1" ]; then
        sudo mount "$EFI_PART" /mnt/boot/efi
    fi
}

# Repair GRUB
repair_grub() {
    case "$DISTRO" in
        arch|endeavouros|cachyos)
            echo -e "${YELLOW}Running Arch-based GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo arch-chroot /mnt /bin/bash -c "
                    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
                    grub-mkconfig -o /boot/grub/grub.cfg
                "
            else
                sudo arch-chroot /mnt /bin/bash -c "
                    grub-install --target=i386-pc /dev/sda
                    grub-mkconfig -o /boot/grub/grub.cfg
                "
            fi
            ;;
        debian|ubuntu)
            echo -e "${YELLOW}Running Debian/Ubuntu GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo chroot /mnt /bin/bash -c "
                    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
                    update-grub
                "
            else
                sudo chroot /mnt /bin/bash -c "
                    grub-install --target=i386-pc /dev/sda
                    update-grub
                "
            fi
            ;;
        fedora)
            echo -e "${YELLOW}Running Fedora GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo chroot /mnt /bin/bash -c "
                    grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            else
                sudo chroot /mnt /bin/bash -c "
                    grub2-install --target=i386-pc /dev/sda
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            fi
            ;;
        opensuse*|suse)
            echo -e "${YELLOW}Running openSUSE GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo chroot /mnt /bin/bash -c "
                    grub2-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            else
                sudo chroot /mnt /bin/bash -c "
                    grub2-install --target=i386-pc /dev/sda
                    grub2-mkconfig -o /boot/grub2/grub.cfg
                "
            fi
            ;;
        nixos)
            echo -e "${YELLOW}Running NixOS GRUB repair...${RESET}"
            if [ "$BOOT_MODE" = "1" ]; then
                sudo nixos-enter /mnt --command "
                    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Linux
                    nixos-rebuild boot
                "
            else
                sudo nixos-enter /mnt --command "
                    grub-install --target=i386-pc /dev/sda
                    nixos-rebuild boot
                "
            fi
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${RESET}"
            exit 1
            ;;
    esac
}

# Finish and ask for reboot
finish_message() {
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    echo -e "${GREEN}"
    cat << "EOF"
  ____   ___  _   _ _____ _   _ 
 |  _ \ / _ \| | | | ____| \ | |
 | | | | | | | | | |  _| |  \| |
 | |_| | |_| | |_| | |___| |\  |
 |____/ \___/ \___/|_____|_| \_|
                                
EOF
    echo -e "${RESET}${CYAN}Done: GRUB repaired in liveuser mode for cases where the motherboard does not recognize the bootloader.${RESET}"
    echo -e "${YELLOW}Total time taken: ${DURATION} seconds${RESET}"
    read -rp "Do you want to reboot now? [y/N]: " REBOOT_CHOICE
    if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Rebooting...${RESET}"
        sudo reboot
    else
        echo -e "${GREEN}You can reboot later manually.${RESET}"
    fi
}

# Main sequence
detect_distro
select_boot_mode
confirm_repair
mount_partitions
repair_grub
finish_message
