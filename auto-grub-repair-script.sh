#!/usr/bin/env bash
#========================================================
#  GRUB Repair Ultimate+
#  Author: Andrew (enhanced by Copilot)
#  License: MIT
#  Description: Multi-distro GRUB repair tool for live environments
#  Supports: Arch, EndeavourOS, Debian, Ubuntu, Fedora, openSUSE, NixOS, CachyOS
#  Features: Multi-language UI, interactive partition selection, UEFI/BIOS detection,
#            proper chroot bind mounts, arch-aware GRUB targets, safer defaults
#========================================================

set -euo pipefail

START_TIME=$(date +%s)

# Colors
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; CYAN="\e[36m"; RESET="\e[0m"

#-----------------------
# Language and messages
#-----------------------
LANG_CODE="en"
case "${LANG:-en}" in
  es_*|es) LANG_CODE="es" ;;
  pt_*|pt) LANG_CODE="pt" ;;
  fr_*|fr) LANG_CODE="fr" ;;
  de_*|de) LANG_CODE="de" ;;
  it_*|it) LANG_CODE="it" ;;
  *) LANG_CODE="en" ;;
esac

declare -A MSG

if [[ "$LANG_CODE" == "es" ]]; then
  MSG[BANNER_TITLE]="GRUB Repair Ultimate"
  MSG[GATHER_INFO]="Recopilando información del sistema..."
  MSG[DETECTED_DISTRO]="Distribución detectada"
  MSG[BOOT_MODE_PROMPT]="Selecciona modo de arranque"
  MSG[UEFI_REC]="1) UEFI (recomendado)"
  MSG[BIOS_LEG]="2) BIOS (Legacy)"
  MSG[DEFAULT_UEFI]="Opción inválida. Usando UEFI por defecto."
  MSG[WARN]="ADVERTENCIA: Esto modificará el cargador de arranque."
  MSG[PROCEED]="¿Deseas continuar? [y/N]: "
  MSG[CANCELLED]="Operación cancelada."
  MSG[SELECT_ROOT]="Elige tu partición raíz"
  MSG[SELECT_EFI]="Elige tu partición EFI (FAT32, ~100–500 MB)"
  MSG[MOUNTING]="Montando particiones y preparando chroot..."
  MSG[RUNNING_REPAIR]="Ejecutando reparación de GRUB para"
  MSG[UNSUPPORTED_DISTRO]="Distribución no soportada"
  MSG[DONE]="Listo: GRUB reparado."
  MSG[TOTAL_TIME]="Tiempo total"
  MSG[REBOOT_NOW]="¿Reiniciar ahora? [y/N]: "
  MSG[REBOOTING]="Reiniciando..."
  MSG[REBOOT_LATER]="Puedes reiniciar más tarde manualmente."
  MSG[AUTO_BOOT_MODE]="Detectado modo de arranque"
  MSG[CHANGE_MODE]="¿Quieres cambiar el modo? [y/N]: "
  MSG[SELECT_DISK]="Elige el disco donde instalar GRUB (solo BIOS/Legacy)"
  MSG[EFI_HINT]="Consejo: en UEFI, selecciona la partición con tipo vfat/FAT32 y etiqueta EFI/ESP."
  MSG[NEED_ROOT]="Este script requiere privilegios de administrador (sudo)."
  MSG[NO_PARTS]="No se detectaron particiones adecuadas."
  MSG[INVALID_SELECTION]="Selección inválida."
  MSG[CHROOT_BIND]="Realizando bind-mounts para chroot..."
  MSG[ARCH_DETECTED]="Arquitectura detectada"
  MSG[EFI_DIR_MISSING]="Creando directorio /mnt/boot/efi..."
  MSG[BOOT_DIR_MISSING]="Creando directorio /mnt/boot..."
  MSG[DISK_FROM_ROOT]="Detectando disco de la raíz seleccionada..."
  MSG[EFI_SKIP_BIOS]="En UEFI no se requiere seleccionar disco."
  MSG[PACKAGE_HINT]="Asegúrate de tener grub instalado en el sistema objetivo."
  MSG[NIXOS_HINT]="En NixOS, la configuración se aplica con nixos-rebuild."
else
  MSG[BANNER_TITLE]="GRUB Repair Ultimate"
  MSG[GATHER_INFO]="Gathering system information..."
  MSG[DETECTED_DISTRO]="Detected distribution"
  MSG[BOOT_MODE_PROMPT]="Select boot mode"
  MSG[UEFI_REC]="1) UEFI (recommended)"
  MSG[BIOS_LEG]="2) BIOS (Legacy)"
  MSG[DEFAULT_UEFI]="Invalid choice. Defaulting to UEFI."
  MSG[WARN]="WARNING: This will modify your bootloader."
  MSG[PROCEED]="Do you want to proceed? [y/N]: "
  MSG[CANCELLED]="Operation cancelled."
  MSG[SELECT_ROOT]="Select your root partition"
  MSG[SELECT_EFI]="Select your EFI partition (FAT32, ~100–500 MB)"
  MSG[MOUNTING]="Mounting partitions and preparing chroot..."
  MSG[RUNNING_REPAIR]="Running GRUB repair for"
  MSG[UNSUPPORTED_DISTRO]="Unsupported distribution"
  MSG[DONE]="Done: GRUB repaired."
  MSG[TOTAL_TIME]="Total time"
  MSG[REBOOT_NOW]="Reboot now? [y/N]: "
  MSG[REBOOTING]="Rebooting..."
  MSG[REBOOT_LATER]="You can reboot later manually."
  MSG[AUTO_BOOT_MODE]="Detected boot mode"
  MSG[CHANGE_MODE]="Do you want to change the mode? [y/N]: "
  MSG[SELECT_DISK]="Select the disk to install GRUB (BIOS/Legacy only)"
  MSG[EFI_HINT]="Hint: in UEFI, pick the partition with vfat/FAT32 type and EFI/ESP label."
  MSG[NEED_ROOT]="This script requires administrator privileges (sudo)."
  MSG[NO_PARTS]="No suitable partitions were detected."
  MSG[INVALID_SELECTION]="Invalid selection."
  MSG[CHROOT_BIND]="Performing bind mounts for chroot..."
  MSG[ARCH_DETECTED]="Detected architecture"
  MSG[EFI_DIR_MISSING]="Creating /mnt/boot/efi directory..."
  MSG[BOOT_DIR_MISSING]="Creating /mnt/boot directory..."
  MSG[DISK_FROM_ROOT]="Determining disk from selected root..."
  MSG[EFI_SKIP_BIOS]="In UEFI you don't need to select a disk."
  MSG[PACKAGE_HINT]="Make sure grub is installed in the target system."
  MSG[NIXOS_HINT]="In NixOS, changes are applied via nixos-rebuild."
fi

#-----------------------
# Banner
#-----------------------
echo -e "${CYAN}"
cat << "EOF"
   ____ ____  _    _ ____  _   _ 
  / ___|  _ \| |  | | __ )| | | |
 | |  _| |_) | |  | |  _ \| | | |
 | |_| |  _ <| |__| | |_) | |_| |
  \____|_| \_\\____/|____/ \___/ 
                                 
EOF
echo -e "${RESET}"
echo -e "${YELLOW}=== ${MSG[BANNER_TITLE]} ===${RESET}"

#-----------------------
# Preflight
#-----------------------
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}${MSG[NEED_ROOT]}${RESET}"
  exit 1
fi

echo -e "${CYAN}${MSG[GATHER_INFO]}${RESET}"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
ARCH=$(uname -m)
echo "${MSG[ARCH_DETECTED]}: $ARCH"

if command -v dmidecode &>/dev/null; then
  MB_MANU=$(dmidecode -s baseboard-manufacturer || true)
  MB_MODEL=$(dmidecode -s baseboard-product-name || true)
  echo "Motherboard: ${MB_MANU} ${MB_MODEL}"
fi
echo "-----------------------------------"

#-----------------------
# Detect distro
#-----------------------
DISTRO=""
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO="$ID"
  echo -e "${GREEN}${MSG[DETECTED_DISTRO]}:${RESET} $DISTRO"
else
  echo -e "${RED}Cannot detect your distribution.${RESET}"
  exit 1
fi

#-----------------------
# Detect boot mode
#-----------------------
BOOT_MODE=""   # 1=UEFI, 2=BIOS
if [ -d /sys/firmware/efi/efivars ]; then
  BOOT_MODE="1"
  echo -e "${GREEN}${MSG[AUTO_BOOT_MODE]}:${RESET} UEFI"
else
  BOOT_MODE="2"
  echo -e "${GREEN}${MSG[AUTO_BOOT_MODE]}:${RESET} BIOS"
fi

read -rp "${MSG[CHANGE_MODE]}" CHANGE
if [[ "$CHANGE" =~ ^[Yy]$ ]]; then
  echo -e "${CYAN}${MSG[BOOT_MODE_PROMPT]}:${RESET}"
  echo "1) UEFI"
  echo "2) BIOS (Legacy)"
  read -rp "Choice [1/2]: " CH
  if [[ "$CH" == "2" ]]; then BOOT_MODE="2"; else BOOT_MODE="1"; fi
fi

#-----------------------
# Confirm
#-----------------------
echo -e "${YELLOW}${MSG[WARN]}${RESET}"
read -rp "${MSG[PROCEED]}" CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo -e "${RED}${MSG[CANCELLED]}${RESET}"
  exit 0
fi

#-----------------------
# Helpers
#-----------------------
require_cmd() { command -v "$1" &>/dev/null || { echo -e "${RED}Missing: $1${RESET}"; exit 1; }; }

list_partitions() {
  lsblk -rpno NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,PARTLABEL,PARTTYPE | awk '$3=="part"{print}'
}

select_from_list() {
  local prompt="$1"; shift
  local -a items=("$@")
  if [[ ${#items[@]} -eq 0 ]]; then
    echo -e "${RED}${MSG[NO_PARTS]}${RESET}"; exit 1
  fi
  echo -e "${CYAN}${prompt}:${RESET}"
  local i=1
  for it in "${items[@]}"; do
    echo "  $i) $it"
    ((i++))
  done
  read -rp ">> " idx
  if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > ${#items[@]} )); then
    echo -e "${RED}${MSG[INVALID_SELECTION]}${RESET}"; exit 1
  fi
  echo "${items[$((idx-1))]}"
}

detect_grub_targets() {
  # Returns UEFI_TARGET and BIOS_TARGET
  UEFI_TARGET="x86_64-efi"
  case "$ARCH" in
    x86_64) UEFI_TARGET="x86_64-efi"; BIOS_TARGET="i386-pc" ;;
    i686|i386) UEFI_TARGET="i386-efi"; BIOS_TARGET="i386-pc" ;;
    aarch64|arm64) UEFI_TARGET="aarch64-efi"; BIOS_TARGET="" ;;
    armv7l|armv8l) UEFI_TARGET="arm-efi"; BIOS_TARGET="" ;;
    *) UEFI_TARGET="x86_64-efi"; BIOS_TARGET="i386-pc" ;;
  esac
  echo "$UEFI_TARGET|$BIOS_TARGET"
}

#-----------------------
# Partition selection
#-----------------------
# Build candidate lists
ROOT_CAND=()
EFI_CAND=()

while IFS= read -r line; do
  # NAME SIZE TYPE FSTYPE MOUNT PARTLABEL PARTTYPE
  NAME=$(awk '{print $1}' <<<"$line")
  SIZE=$(awk '{print $2}' <<<"$line")
  FSTYPE=$(awk '{print $4}' <<<"$line")
  PARTTYPE=$(awk '{print $7}' <<<"$line")
  DESC="$NAME  [$SIZE]  fs:$FSTYPE type:$PARTTYPE"
  # Root candidates: typical Linux filesystems
  case "$FSTYPE" in
    ext2|ext3|ext4|xfs|btrfs|f2fs|reiserfs) ROOT_CAND+=("$DESC") ;;
  esac
  # EFI candidates: vfat with GPT ESP GUID or label
  if [[ "$FSTYPE" == "vfat" || "$FSTYPE" == "fat32" ]]; then
    EFI_CAND+=("$DESC")
  fi
done < <(list_partitions)

ROOT_SEL=$(select_from_list "${MSG[SELECT_ROOT]}" "${ROOT_CAND[@]}")
ROOT_PART=$(awk '{print $1}' <<<"$ROOT_SEL")

if [[ "$BOOT_MODE" == "1" ]]; then
  echo -e "${YELLOW}${MSG[EFI_HINT]}${RESET}"
  EFI_SEL=$(select_from_list "${MSG[SELECT_EFI]}" "${EFI_CAND[@]}")
  EFI_PART=$(awk '{print $1}' <<<"$EFI_SEL")
fi

# If BIOS, pick disk from root partition's parent
if [[ "$BOOT_MODE" == "2" ]]; then
  echo -e "${CYAN}${MSG[DISK_FROM_ROOT]}${RESET}"
  ROOT_DISK=$(lsblk -no PKNAME "$ROOT_PART")
  # Fallback: if empty, derive by stripping partition suffix
  if [[ -z "$ROOT_DISK" ]]; then
    ROOT_DISK=$(basename "$ROOT_PART" | sed -E 's/p?[0-9]+$//')
  fi
  # Present disk list anyway for confirmation
  DISKS=($(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}'))
  DISP=()
  for d in "${DISKS[@]}"; do
    if [[ "$(basename "$d")" == "$ROOT_DISK" ]]; then
      DISP+=("$d  [root-disk]")
    else
      DISP+=("$d")
    fi
  done
  DISK_SEL=$(select_from_list "${MSG[SELECT_DISK]}" "${DISP[@]}")
  INSTALL_DISK=$(awk '{print $1}' <<<"$DISK_SEL")
else
  INSTALL_DISK=""
  echo -e "${GREEN}${MSG[EFI_SKIP_BIOS]}${RESET}"
fi

#-----------------------
# Mounting and chroot prep
#-----------------------
echo -e "${CYAN}${MSG[MOUNTING]}${RESET}"
mkdir -p /mnt
mountpoint -q /mnt || mount "$ROOT_PART" /mnt

# Ensure /boot and /boot/efi
if [[ ! -d /mnt/boot ]]; then
  echo -e "${YELLOW}${MSG[BOOT_DIR_MISSING]}${RESET}"
  mkdir -p /mnt/boot
fi

if [[ "$BOOT_MODE" == "1" ]]; then
  if [[ ! -d /mnt/boot/efi ]]; then
    echo -e "${YELLOW}${MSG[EFI_DIR_MISSING]}${RESET}"
    mkdir -p /mnt/boot/efi
  fi
  mountpoint -q /mnt/boot/efi || mount "$EFI_PART" /mnt/boot/efi
fi

echo -e "${CYAN}${MSG[CHROOT_BIND]}${RESET}"
for d in dev proc sys run; do
  mountpoint -q /mnt/$d || mount --bind /$d /mnt/$d
done

#-----------------------
# Determine GRUB targets
#-----------------------
IFS="|" read -r UEFI_TARGET BIOS_TARGET <<<"$(detect_grub_targets)"

#-----------------------
# Repair per distro
#-----------------------
echo -e "${YELLOW}${MSG[RUNNING_REPAIR]}:${RESET} $DISTRO"
echo -e "${YELLOW}${MSG[PACKAGE_HINT]}${RESET}"
case "$DISTRO" in
  arch|endeavouros|cachyos)
    if [[ "$BOOT_MODE" == "1" ]]; then
      chroot /mnt /bin/bash -c "
        grub-install --target=${UEFI_TARGET} --efi-directory=/boot/efi --bootloader-id=Linux
        grub-mkconfig -o /boot/grub/grub.cfg
      "
    else
      [[ -n "$BIOS_TARGET" ]] || { echo -e "${RED}BIOS target not supported on this arch.${RESET}"; exit 1; }
      chroot /mnt /bin/bash -c "
        grub-install --target=${BIOS_TARGET} ${INSTALL_DISK}
        grub-mkconfig -o /boot/grub/grub.cfg
      "
    fi
    ;;
  debian|ubuntu|linuxmint|pop)
    if [[ "$BOOT_MODE" == "1" ]]; then
      chroot /mnt /bin/bash -c "
        grub-install --target=${UEFI_TARGET} --efi-directory=/boot/efi --bootloader-id=Linux
        update-grub
      "
    else
      [[ -n "$BIOS_TARGET" ]] || { echo -e "${RED}BIOS target not supported on this arch.${RESET}"; exit 1; }
      chroot /mnt /bin/bash -c "
        grub-install --target=${BIOS_TARGET} ${INSTALL_DISK}
        update-grub
      "
    fi
    ;;
  fedora)
    if [[ "$BOOT_MODE" == "1" ]]; then
      chroot /mnt /bin/bash -c "
        grub2-install --target=${UEFI_TARGET} --efi-directory=/boot/efi --bootloader-id=Linux
        grub2-mkconfig -o /boot/grub2/grub.cfg
      "
    else
      [[ -n "$BIOS_TARGET" ]] || { echo -e "${RED}BIOS target not supported on this arch.${RESET}"; exit 1; }
      chroot /mnt /bin/bash -c "
        grub2-install --target=${BIOS_TARGET} ${INSTALL_DISK}
        grub2-mkconfig -o /boot/grub2/grub.cfg
      "
    fi
    ;;
  opensuse*|suse|opensuse-tumbleweed|opensuse-leap)
    if [[ "$BOOT_MODE" == "1" ]]; then
      chroot /mnt /bin/bash -c "
        grub2-install --target=${UEFI_TARGET} --efi-directory=/boot/efi --bootloader-id=Linux
        grub2-mkconfig -o /boot/grub2/grub.cfg
      "
    else
      [[ -n "$BIOS_TARGET" ]] || { echo -e "${RED}BIOS target not supported on this arch.${RESET}"; exit 1; }
      chroot /mnt /bin/bash -c "
        grub2-install --target=${BIOS_TARGET} ${INSTALL_DISK}
        grub2-mkconfig -o /boot/grub2/grub.cfg
      "
    fi
    ;;
  nixos)
    echo -e "${YELLOW}${MSG[NIXOS_HINT]}${RESET}"
    if command -v nixos-enter &>/dev/null; then
      if [[ "$BOOT_MODE" == "1" ]]; then
        nixos-enter /mnt --command "
          grub-install --target=${UEFI_TARGET} --efi-directory=/boot/efi --bootloader-id=Linux || true
          nixos-rebuild boot
        "
      else
        [[ -n "$BIOS_TARGET" ]] || { echo -e "${RED}BIOS target not supported on this arch.${RESET}"; exit 1; }
        nixos-enter /mnt --command "
          grub-install --target=${BIOS_TARGET} ${INSTALL_DISK} || true
          nixos-rebuild boot
        "
      fi
    else
      # Fallback chroot
      if [[ "$BOOT_MODE" == "1" ]]; then
        chroot /mnt /bin/bash -c "
          grub-install --target=${UEFI_TARGET} --efi-directory=/boot/efi --bootloader-id=Linux || true
          nixos-rebuild boot
        "
      else
        [[ -n "$BIOS_TARGET" ]] || { echo -e "${RED}BIOS target not supported on this arch.${RESET}"; exit 1; }
        chroot /mnt /bin/bash -c "
          grub-install --target=${BIOS_TARGET} ${INSTALL_DISK} || true
          nixos-rebuild boot
        "
      fi
    fi
    ;;
  *)
    echo -e "${RED}${MSG[UNSUPPORTED_DISTRO]}: $DISTRO${RESET}"
    exit 1
    ;;
esac

#-----------------------
# Finish
#-----------------------
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
echo -e "${RESET}${CYAN}${MSG[DONE]}${RESET}"
echo -e "${YELLOW}${MSG[TOTAL_TIME]}: ${DURATION} s${RESET}"
read -rp "${MSG[REBOOT_NOW]}" REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}${MSG[REBOOTING]}${RESET}"
  reboot
else
  echo -e "${GREEN}${MSG[REBOOT_LATER]}${RESET}"
fi
