# Auto-GRUB-Repair-Script (GRUBU)

A simple script that **automatically mounts partitions** and **reinstalls GRUB** to restore your system’s bootloader.  
Perfect for use from a **live environment** when your motherboard fails to detect the bootloader.

---

## ✅ Supported Distributions
- **Arch Linux**
- **EndeavourOS**
- **Debian**
- **Ubuntu**
- **Fedora**

---

## 📦 Prerequisites
- A **live USB** or live environment of any supported distro  
- **Git** installed (check with `git --version`)  
  - If not installed, install it using your package manager:  
    ```bash
    # Debian/Ubuntu
    sudo apt install git
    
    # Fedora
    sudo dnf install git
    
    # Arch/EndeavourOS
    sudo pacman -S git
    ```

---

## How to Use

1. **Clone the repository**
    ```bash
    git clone https://github.com/AndresDev859674/Auto-GRUB-Repair-Script.git
    ```

2. **Navigate into the project folder**
    ```bash
    cd Auto-GRUB-Repair-Script
    ```

3. **Run the script**
    ```bash
    ./auto-grub-repair-script.sh
    ```

4. **Follow the on-screen instructions**  
   The script will:
   - Detect and mount your system partitions  
   - Reinstall GRUB automatically  
   - Restore your bootloader so you can boot normally again  

---

## ⚠️ Notes
- Run this script **only** from a live environment — not from your main OS.  
- Make sure you have **internet access** during the process (some distros require it for package installation).  

---
