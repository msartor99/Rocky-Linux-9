#!/bin/bash
# ==============================================================================
# Post-Installation Script: X11 + SDDM + MaXX Interactive Desktop (Octane)
# Target OS: Rocky Linux 9 (Minimal Install / Server without GUI)
# GPU Driver: Open-source 'nouveau' (KMS / Glamor) & standard X11 drivers
# Design: Strictly Idempotent (safe to run multiple times)
# ==============================================================================

set -euo pipefail

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (or via sudo)."
  exit 1
fi

# 2. Ensure 'whiptail' (newt) is available (idempotent check)
if ! command -v whiptail &> /dev/null; then
  echo "==> Installing 'newt' (whiptail) utility for interactive configuration..."
  dnf install -y newt
fi

# 3. Display Disclaimer and request operator acceptance via whiptail
if ! whiptail --backtitle "MaXX Interactive Desktop Setup - Rocky Linux 9" \
  --title "DISCLAIMER & WARNING" \
  --yes-button "Accept" --no-button "Decline" \
  --yesno "This idempotent script will configure or update this Rocky Linux 9 system:\n\n\
  1. Configure system locale and console/X11 keyboard layouts.\n\
  2. Enable CRB and EPEL repositories and update packages.\n\
  3. Install Xorg server, 'nouveau' GPU driver, and SDDM display manager.\n\
  4. Install Motif/X11 compatibility libraries and required fonts.\n\
  5. Install or verify MaXX Interactive Desktop in /opt/MaXX.\n\
  6. Configure custom SGI splash screen (Maldives theme) and desktop wallpaper.\n\
  7. Ensure default systemd target is 'graphical.target'.\n\n\
WARNING: This script is provided 'AS IS' without warranty of any kind. Ensure you have a backup or snapshot before proceeding.\n\n\
Do you accept these terms and wish to proceed?" 22 78; then
  clear
  echo "==> Execution aborted by operator. No changes were made."
  exit 0
fi

# 4. Interactive Menu: System Language Selection
LANG_CHOICE=$(whiptail --backtitle "MaXX Interactive Desktop Setup - Rocky Linux 9" \
  --title "System Language Selection" \
  --menu "Select the default system language:" 15 60 5 \
  "1" "English (en_US.UTF-8)" \
  "2" "French (fr_FR.UTF-8)" \
  "3" "German (de_DE.UTF-8)" \
  "4" "Italian (it_IT.UTF-8)" \
  "5" "Spanish (es_ES.UTF-8)" \
  3>&1 1>&2 2>&3) || { clear; echo "Error: Language selection cancelled by operator. Exiting."; exit 1; }

case "$LANG_CHOICE" in
  1) SYS_LOCALE="en_US.UTF-8"; LANGPACK="glibc-langpack-en" ;;
  2) SYS_LOCALE="fr_FR.UTF-8"; LANGPACK="glibc-langpack-fr" ;;
  3) SYS_LOCALE="de_DE.UTF-8"; LANGPACK="glibc-langpack-de" ;;
  4) SYS_LOCALE="it_IT.UTF-8"; LANGPACK="glibc-langpack-it" ;;
  5) SYS_LOCALE="es_ES.UTF-8"; LANGPACK="glibc-langpack-es" ;;
esac

# 5. Interactive Menu: Keyboard Layout Selection
KB_CHOICE=$(whiptail --backtitle "MaXX Interactive Desktop Setup - Rocky Linux 9" \
  --title "Keyboard Layout Selection" \
  --menu "Select the console and X11 keyboard layout:" 18 65 9 \
  "1" "English (US - QWERTY)" \
  "2" "English (UK - QWERTY)" \
  "3" "French (France - AZERTY)" \
  "4" "Swiss French (Suisse Romand - QWERTZ)" \
  "5" "German (Germany - QWERTZ)" \
  "6" "Swiss German (Deutschschweiz - QWERTZ)" \
  "7" "Italian (Italy - QWERTY)" \
  "8" "Swiss Italian (Svizzera Italiana - QWERTZ)" \
  "9" "Spanish (Spain - QWERTY)" \
  3>&1 1>&2 2>&3) || { clear; echo "Error: Keyboard selection cancelled by operator. Exiting."; exit 1; }

case "$KB_CHOICE" in
  1) VC_KEYMAP="us";       X11_LAYOUT="us"; X11_VARIANT="" ;;
  2) VC_KEYMAP="gb";       X11_LAYOUT="gb"; X11_VARIANT="" ;;
  3) VC_KEYMAP="fr";       X11_LAYOUT="fr"; X11_VARIANT="" ;;
  4) VC_KEYMAP="ch-fr";    X11_LAYOUT="ch"; X11_VARIANT="fr" ;;
  5) VC_KEYMAP="de";       X11_LAYOUT="de"; X11_VARIANT="" ;;
  6) VC_KEYMAP="ch";       X11_LAYOUT="ch"; X11_VARIANT="de_nodeadkeys" ;;
  7) VC_KEYMAP="it";       X11_LAYOUT="it"; X11_VARIANT="" ;;
  8) VC_KEYMAP="ch-fr";    X11_LAYOUT="ch"; X11_VARIANT="fr" ;;
  9) VC_KEYMAP="es";       X11_LAYOUT="es"; X11_VARIANT="" ;;
esac

# 6. If MaXX is already installed, ask operator whether to keep or reinstall
REINSTALL_MAXX="yes"
if [ -d "/opt/MaXX" ] && [ -f "/opt/MaXX/share/xsessions/maxx.desktop" ]; then
  if whiptail --backtitle "MaXX Interactive Desktop Setup - Rocky Linux 9" \
    --title "Existing MaXX Installation Detected" \
    --yes-button "Keep Existing" --no-button "Reinstall MaXX" \
    --yesno "MaXX Interactive Desktop is already installed in /opt/MaXX.\n\n\
Would you like to KEEP the existing MaXX installation (faster, only updates system/locale/keyboard/artwork) or REINSTALL it from scratch?" 13 75; then
    REINSTALL_MAXX="no"
  else
    REINSTALL_MAXX="yes"
  fi
fi

clear

# 7. Start idempotent installation and system configuration process
echo "==> [1/8] Verifying CRB and EPEL repositories..."
dnf install -y dnf-plugins-core
dnf config-manager --set-enabled crb

if ! rpm -q epel-release &> /dev/null; then
  dnf install -y epel-release
else
  echo "    -> epel-release package is already installed."
fi

dnf config-manager --set-enabled epel || true
dnf update -y

echo "==> [2/8] Installing/Verifying Xorg server, 'nouveau' GPU driver, and SDDM..."
dnf install -y --skip-broken \
  pciutils \
  linux-firmware \
  xorg-x11-server-Xorg \
  xorg-x11-xinit \
  xorg-x11-xauth \
  xorg-x11-drv-nouveau \
  xorg-x11-drv-libinput \
  xorg-x11-drv-evdev \
  xorg-x11-drv-vesa \
  xorg-x11-drv-fbdev \
  xorg-x11-drv-vmware \
  xorg-x11-drv-qxl \
  mesa-dri-drivers \
  mesa-vulkan-drivers \
  mesa-libGL \
  mesa-libEGL \
  mesa-libGLU \
  libglvnd-glx \
  libglvnd-egl \
  libglvnd-opengl \
  sddm \
  sddm-themes \
  dbus-x11 \
  polkit

# Ensure 'nouveau' kernel module is not blacklisted and loads automatically
rm -f /etc/modprobe.d/*blacklist*nouveau*.conf
echo "nouveau" > /etc/modules-load.d/nouveau.conf
modprobe nouveau || true

# Configure Xorg to bind KMS 'nouveau' cleanly with Glamor acceleration
mkdir -p /etc/X11/xorg.conf.d
cat << 'EOF' > /etc/X11/xorg.conf.d/20-nouveau.conf
Section "OutputClass"
    Identifier "Nvidia Nouveau KMS"
    MatchDriver "nouveau"
    Driver "modesetting"
    Option "AccelMethod" "glamor"
EndSection
EOF

echo "==> [3/8] Configuring System Locale and Keyboard Layouts (Console & X11)..."
dnf install -y "$LANGPACK"
localectl set-locale LANG="$SYS_LOCALE"
localectl set-keymap "$VC_KEYMAP"

if [ -n "$X11_VARIANT" ]; then
  localectl set-x11-keymap "$X11_LAYOUT" pc105 "$X11_VARIANT"
else
  localectl set-x11-keymap "$X11_LAYOUT" pc105
fi

echo "    -> Locale set to: $SYS_LOCALE"
echo "    -> Console keymap set to: $VC_KEYMAP"
echo "    -> X11 layout set to: $X11_LAYOUT ${X11_VARIANT:+(variant: $X11_VARIANT)}"

echo "==> [4/8] Installing/Verifying MaXX Desktop dependencies and utilities..."
dnf install -y --skip-broken \
  wget \
  tar \
  bzip2 \
  cpp \
  ncurses \
  ncurses-compat-libs \
  pavucontrol \
  alsa-utils \
  xterm \
  xterm-resize \
  motif \
  libXp \
  libXpm \
  libXmu \
  libXt \
  libXext \
  libXft \
  gtk2 \
  gtk3 \
  ImageMagick

echo "==> [5/8] Installing/Verifying X11 (Bitmap/ISO8859-1) and TrueType fonts..."
dnf install -y --skip-broken \
  xorg-x11-fonts-misc \
  xorg-x11-fonts-75dpi \
  xorg-x11-fonts-ISO8859-1-75dpi \
  xorg-x11-fonts-100dpi \
  xorg-x11-fonts-ISO8859-1-100dpi \
  dejavu-sans-mono-fonts \
  google-noto-fonts-common \
  google-noto-sans-fonts \
  google-noto-sans-mono-fonts

echo "==> [6/8] Processing MaXX Interactive Desktop installation..."
MAXX_URL="https://s3.ca-central-1.amazonaws.com/cdn.maxxinteractive.com/maxx-desktop-installer/MaXX-Desktop-LINUX-x86_64-2.2.0-Installer.sh"
INSTALLER="/tmp/MaXX-Desktop-LINUX-x86_64-2.2.0-Installer.sh"

if [ "$REINSTALL_MAXX" = "yes" ]; then
  if [ -d "/opt/MaXX" ]; then
    echo "    -> Rotating existing /opt/MaXX to /opt/MaXX.bak..."
    rm -rf /opt/MaXX.bak
    mv /opt/MaXX /opt/MaXX.bak
    rm -rf /usr/share/themes/{IndigoMagic,Rio,Gotham,MaXX*}
  fi

  if [ ! -s "$INSTALLER" ]; then
    echo "    -> Downloading MaXX Desktop installer..."
    wget -q --show-progress -O "$INSTALLER" "$MAXX_URL"
  else
    echo "    -> Using cached installer in $INSTALLER..."
  fi

  chmod a+x "$INSTALLER"
  "$INSTALLER"
else
  echo "    -> Skipping MaXX reinstallation (preserving existing /opt/MaXX)."
fi

echo "==> [7/8] Configuring SGI Splash Screen (Maldives theme) and Desktop Wallpaper..."
SPLASH_URL="https://raw.githubusercontent.com/msartor99/FreeBSD15-Maxxdesktop/main/SGI_splash.jpg"
WALLPAPER_URL="https://raw.githubusercontent.com/msartor99/FreeBSD15-Maxxdesktop/main/sgi_desktop.jpg"
SPLASH_DEST="/usr/share/backgrounds/sgi/SGI_splash.jpg"
WALLPAPER_DEST="/usr/share/backgrounds/sgi/sgi_desktop.jpg"

mkdir -p /usr/share/backgrounds/sgi
mkdir -p /opt/MaXX/share/backgrounds

if [ ! -s "$SPLASH_DEST" ]; then
  wget -q --show-progress -O "$SPLASH_DEST" "$SPLASH_URL"
else
  echo "    -> SGI_splash.jpg already present, skipping download."
fi

if [ ! -s "$WALLPAPER_DEST" ]; then
  wget -q --show-progress -O "$WALLPAPER_DEST" "$WALLPAPER_URL"
else
  echo "    -> sgi_desktop.jpg already present, skipping download."
fi

if [ ! "$SPLASH_DEST" -ef /opt/MaXX/share/backgrounds/SGI_splash.jpg ]; then
  cp -f "$SPLASH_DEST" /opt/MaXX/share/backgrounds/SGI_splash.jpg
fi
if [ ! "$WALLPAPER_DEST" -ef /opt/MaXX/share/backgrounds/sgi_desktop.jpg ]; then
  cp -f "$WALLPAPER_DEST" /opt/MaXX/share/backgrounds/sgi_desktop.jpg
fi
chmod 644 /usr/share/backgrounds/sgi/*.jpg /opt/MaXX/share/backgrounds/*.jpg

# Configure SDDM to strictly use X11, 'maldives' theme, and custom SGI splash background
mkdir -p /etc/sddm.conf.d
cat << 'EOF' > /etc/sddm.conf.d/10-sgi-theme.conf
[General]
DisplayServer=x11

[Theme]
Current=maldives
EOF

for THEME_DIR in /usr/share/sddm/themes/*; do
  if [ -d "$THEME_DIR" ]; then
    cat << EOF > "$THEME_DIR/theme.conf.user"
[General]
background=/usr/share/backgrounds/sgi/SGI_splash.jpg
type=image
EOF
  fi
done

# Idempotently write X11 wallpaper autoload script
mkdir -p /etc/X11/xinit/xinitrc.d
cat << 'EOF' > /etc/X11/xinit/xinitrc.d/99-sgi-wallpaper.sh
#!/bin/sh
WALLPAPER="/usr/share/backgrounds/sgi/sgi_desktop.jpg"
if [ -f "$WALLPAPER" ]; then
  if command -v display >/dev/null 2>&1; then
    display -window root -backdrop "$WALLPAPER" &
  elif [ -x "/opt/MaXX/bin/xsetbg" ]; then
    /opt/MaXX/bin/xsetbg -fullscreen "$WALLPAPER" &
  fi
fi
EOF
chmod +x /etc/X11/xinit/xinitrc.d/99-sgi-wallpaper.sh

echo "==> [8/8] Verifying SDDM and graphical boot target..."
mkdir -p /usr/share/xsessions
if [ -f /opt/MaXX/share/xsessions/maxx.desktop ] && [ ! -e /usr/share/xsessions/maxx.desktop ]; then
  ln -sf /opt/MaXX/share/xsessions/maxx.desktop /usr/share/xsessions/maxx.desktop
fi

systemctl enable sddm.service --force
systemctl set-default graphical.target

echo "================================================================================"
echo " Setup & Verification completed successfully!"
echo "   - System Language   : $SYS_LOCALE"
echo "   - X11 Keyboard      : $X11_LAYOUT ${X11_VARIANT:+($X11_VARIANT)}"
echo "   - GPU Driver        : nouveau (KMS / modesetting)"
echo "   - SDDM Theme        : maldives (with custom SGI splash)"
echo "   - MaXX Reinstalled  : $REINSTALL_MAXX"
echo "   - Splash Screen     : $SPLASH_DEST"
echo "   - Desktop Wallpaper : $WALLPAPER_DEST"
echo ""
echo " Reboot the system using the command: reboot"
echo " On the SDDM login screen, select 'MaXX Interactive Desktop' in the Session menu."
echo "================================================================================"