# Rocky Linux 9 — MaXX Interactive Desktop (Octane Edition) Automated Setup

An automated, **strictly idempotent** post-installation script designed to transform a fresh **Rocky Linux 9 Minimal Install** (or Server without GUI) into a fully featured **Silicon Graphics (SGI) IRIX / IndigoMagic** workstation environment powered by **MaXX Interactive Desktop (Octane Edition v2.2)**.

---

## Key Features

* **Strictly Idempotent Design:** Safe to run multiple times without breaking the system or exhausting disk space. Running the script again allows you to seamlessly switch system locales, keyboard layouts, or GPU drivers, and prompts whether to keep or reinstall `/opt/MaXX`.
* **Interactive TUI Configuration (`whiptail`):**
  * **Operator Disclaimer:** Interactive acceptance prompt before any system modification.
  * **System Locale Selection:** English (`en_US`), French (`fr_FR`), German (`de_DE`), Italian (`it_IT`), and Spanish (`es_ES`).
  * **Console, X11 & Shell Keyboard Layouts:** Full support for US, UK, French (AZERTY), Swiss French (*Suisse Romand* - QWERTZ), German, Swiss German, Italian, Swiss Italian, and Spanish keyboards across the Linux console, SDDM, X11, and all MaXX terminals (`xterm`, `Unix Shell`, `Admin Shell`).
  * **Automatic GPU Detection & Driver Selection:** Detects your graphics adapter via `lspci`, displays it at the top of the menu, and configures the selected driver stack:
    * **Nouveau** — Open-Source NVIDIA driver (KMS / Glamor — Recommended default)
    * **NVIDIA Latest** — Proprietary NVIDIA driver (Latest branch via CUDA RHEL9 / RPM Fusion)
    * **NVIDIA 550** — Proprietary NVIDIA driver (550 Production / LTS branch)
    * **NVIDIA 470** — Proprietary NVIDIA driver (470 Legacy Kepler branch via RPM Fusion)
    * **AMD / ATI** — Open-Source `amdgpu` / `radeon` driver (Mesa KMS + DRI3)
    * **Intel** — Open-Source Intel HD / Iris / Arc driver (`modesetting` + Glamor + VA-API)
    * **VM / VESA** — Virtual Machine drivers (`vmware`, `qxl`, `vesa`, `fbdev`)
* **Complete Desktop Application Suite:**
  * **Office Suite:** LibreOffice (`Writer`, `Calc`, `Impress`, `Draw`, `Math`) with localized language packs and `openoffice`/`soffice` symlinks.
  * **Web & Mail:** Mozilla Firefox & Mozilla Thunderbird.
  * **Multimedia & Audio:** VLC Media Player (via RPM Fusion) & PulseAudio/ALSA volume control (`pavucontrol`).
  * **PDF Viewer:** Evince Document Viewer automatically linked to `pdfview` and `xpdf` for native MaXX Desktop menu integration.
* **Built-in MaXX v2.2 Fixes for Rocky Linux 9:**
  * Fixes restrictive file permissions on ROX-Filer `MIME-types` in `/opt/MaXX/share/misc/HOME` (eliminating the "red triangle" missing icon issue).
  * Automatically cleans stale `/tmp/MaXXisRunning-$USER` session lock files on startup.
  * Overrides hardcoded `setxkbmap us` calls inside MaXX's `desktopenv` with the operator's chosen keyboard layout.
  * Provides an interactive `maxx-background-setter` utility bound to **`Desktop -> Customize -> Background`** to change wallpapers live on the ROX-Filer Pinboard.
* **Custom SGI Artwork & SDDM Theme:**
  * Configures SDDM in strict X11 mode using the **`maldives`** theme and a custom SGI login splash screen (`SGI_splash.jpg`).
  * Applies a custom SGI desktop wallpaper (`sgi_desktop.jpg`) by default on the MaXX ROX-Filer Pinboard.

---

## Prerequisites

* **Operating System:** Rocky Linux 9 (x86_64) — *Minimal Install* or *Server* (without GNOME/KDE).
* **Privileges:** Root access (`root` or `sudo`).
* **Network:** Active internet connection to fetch packages, repositories, and the MaXX installer.

---

## Quick Start / Installation

### Option 1: Direct Download via `curl` (Recommended)

Connect to your Rocky Linux 9 system via SSH (e.g., PuTTY) or console as `root` and run:

```bash
# 1. Remove any cached script and download the latest version from GitHub
rm -f install-maxx-rocky9.sh
curl -fsSL -H 'Cache-Control: no-cache' \
  "[https://raw.githubusercontent.com/msartor99/Rocky-Linux-9/main/install-maxx-rocky9.sh?$(date](https://raw.githubusercontent.com/msartor99/Rocky-Linux-9/main/install-maxx-rocky9.sh?$(date) +%s)" \
  -o install-maxx-rocky9.sh

# 2. Make the script executable and run it
chmod +x install-maxx-rocky9.sh
sudo ./install-maxx-rocky9.sh
