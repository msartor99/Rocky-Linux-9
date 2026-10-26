# Rocky Linux 9 — MaXX Interactive Desktop Post-Install Script

![OS](https://img.shields.io/badge/OS-Rocky%20Linux%209-10B981?logo=rockylinux&logoColor=white)
![Architecture](https://img.shields.io/badge/Arch-x86__64-blue)
![Display Server](https://img.shields.io/badge/X11-Xorg%20%2B%20SDDM-orange)
![Desktop](https://img.shields.io/badge/Desktop-MaXX%20Interactive%20(Octane%20v2.2)-purple)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

An automated, interactive post-installation script designed to transform a fresh **Rocky Linux 9 Minimal Install** (or Server without GUI) into a complete graphical workstation running **MaXX Interactive Desktop** (SGI IRIX / Indigo Magic look & feel) on top of a lightweight **Xorg** and **SDDM** stack.

---

## ✨ Features

* **Safety First:** Displays a clear disclaimer and requires explicit operator confirmation before making any system changes.
* **Interactive TUI Configuration (`dialog`):**
  * **System Locale Selection:** English (`en_US`), French (`fr_FR`), German (`de_DE`), Italian (`it_IT`), and Spanish (`es_ES`) with automatic `glibc-langpack` installation.
  * **Keyboard Layout Synchronization:** Configures both the virtual console (`vconsole`) and the **X11 / SDDM** keymaps simultaneously (supports US, UK, FR, DE, IT, ES, as well as **Swiss French**, **Swiss German**, and **Swiss Italian** layouts).
* **Lightweight X11 Stack:** Installs a standalone Xorg server, Mesa DRI/Vulkan drivers, and the **SDDM** display manager without pulling bloated desktop environments (no GNOME or KDE dependencies).
* **Complete MaXX Prerequisites:** Automatically enables `CRB` and `EPEL` repositories, installs Motif/X11 compatibility libraries, audio utilities (`pavucontrol`, `alsa-utils`), and legacy ISO8859-1 bitmap/TrueType fonts required by SGI/Motif applications.
* **Automated MaXX Deployment:** Downloads and executes the official **MaXX Interactive Desktop v2.2.0 (Octane Edition)** installer into `/opt/MaXX` (with automatic backup if a previous installation is detected).

---

## 📋 Prerequisites

* **Operating System:** Fresh installation of **Rocky Linux 9** (`x86_64` — Minimal or Server without GUI).
* **Memory:** 4 GB RAM minimum (8 GB recommended).
* **Disk Space:** At least 250 MB free in `/tmp` and 800 MB free in `/opt`.
* **Privileges:** Root access or a user with `sudo` privileges.
* **Network:** Active internet connection to fetch packages and the MaXX installer.

---

## 🚀 Quick Start (Download & Install)

### Option 1: Direct Download via `curl` (Recommended on Minimal Install)
Since `git` is not installed by default on a Rocky Linux 9 Minimal installation, you can fetch and execute the script directly using `curl`:

```bash
# 1. update Rocky Linux 9

dnf update
# 2. Download the script from GitHub

curl -fsSLO [https://raw.githubusercontent.com/msartor99/Rocky-Linux-9/main/install-maxx-rocky9.sh](https://raw.githubusercontent.com/msartor99/Rocky-Linux-9/main/install-maxx-rocky9.sh)

# 2. Make the script executable and run it
chmod +x install-maxx-rocky9.sh
sudo ./install-maxx-rocky9.sh
```

### Option 2: Clone the Repository via `git`
If you prefer cloning the full repository:

```bash
# 1. Install git (if not already present) and clone the repository
sudo dnf install -y git
git clone [https://github.com/msartor99/Rocky-Linux-9.git](https://github.com/msartor99/Rocky-Linux-9.git)
cd Rocky-Linux-9

# 2. Make the script executable and run it
chmod +x install-maxx-rocky9.sh
sudo ./install-maxx-rocky9.sh
```

### Interactive Setup Steps
1. Type `yes` to accept the disclaimer.
2. Select your preferred **System Language** in the interactive menu.
3. Select your **Keyboard Layout** in the second menu.
4. Once the installation finishes, reboot your machine:
   ```bash
   sudo reboot
   ```

---

## 🖥️ Post-Installation & First Login

1. After rebooting, you will be greeted by the **SDDM** graphical login screen.
2. In the **Session** drop-down menu, select **MaXX Interactive Desktop**.
3. Log in using a **standard (non-root) user account**.

> **Note for upgrading users:** If your user account had a previous version of MaXX Desktop configured, reset your user preferences before logging in via SDDM by running:
> ```bash
> mv ~/.maxxdesktop ~/dot.maxxdesktop-back
> ```

---

## 🛠️ What the Script Does (Step-by-Step)

| Step | Action |
| :--- | :--- |
| **Pre-Flight** | Checks `root` privileges, displays disclaimer, installs `dialog`, and prompts for language/keyboard settings. |
| **[1/7]** | Enables **CRB** (CodeReady Builder) and **EPEL** repositories, then performs a full `dnf update`. |
| **[2/7]** | Installs `Xorg`, `libinput`, `Mesa` drivers, `SDDM`, `dbus-x11`, and `polkit`. |
| **[3/7]** | Installs the selected `glibc-langpack` and applies locale & keyboard settings to both Console and X11 via `localectl`. |
| **[4/7]** | Installs Motif/X11 runtime libraries (`motif`, `libXp`, `libXpm`, `ncurses-compat-libs`, `gtk2`, `gtk3`, `xterm`, etc.). |
| **[5/7]** | Installs legacy X11 75dpi/100dpi ISO8859-1 bitmap fonts and modern Google Noto / DejaVu TrueType fonts. |
| **[6/7]** | Backs up any existing `/opt/MaXX` directory, downloads the official MaXX v2.2.0 installer, and runs it. |
| **[7/7]** | Ensures `maxx.desktop` is registered in `/usr/share/xsessions/`, enables `sddm.service`, and sets `graphical.target` as default. |

---

## ⚠️ Disclaimer

This script is provided **"AS IS"**, without warranty of any kind. Always ensure you have a backup or a VM snapshot before running automated post-installation scripts on your system. **MaXX Interactive Desktop** is developed and maintained by the [MaXX Interactive Desktop Project](https://www.maxxinteractive.com/).
