#!/bin/bash
# ==============================================================================
# Post-Installation Script: X11 + SDDM + MaXX Interactive Desktop (Octane)
# Target OS: Rocky Linux 9 (Minimal Install / Server without GUI)
# ==============================================================================

set -e

# 1. Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (or via sudo)."
  exit 1
fi

# 2. Display Disclaimer and request operator acceptance
clear
cat << "EOF"
================================================================================
                                  DISCLAIMER
================================================================================
This script will make significant changes to this Rocky Linux 9 system:

  1. Configure system locale and console/X11 keyboard layouts.
  2. Enable third-party repositories (CRB and EPEL) and perform a full update.
  3. Install an Xorg display server, Mesa drivers, and the SDDM display manager.
  4. Install Motif/X11 compatibility libraries and required legacy/modern fonts.
  5. Download and execute the official MaXX Interactive Desktop installer
     into /opt/MaXX.
  6. Change the default systemd target to 'graphical.target'.

WARNING: This script is provided "AS IS", without warranty of any kind. Ensure
you have a full backup or a system snapshot before proceeding. The operator
assumes all responsibility for running this script.
================================================================================
EOF

read -r -p "Do you accept these terms and wish to proceed with the installation? (yes/no): " CONFIRMATION

case "$CONFIRMATION" in
  [yY][eE][sS]|[yY])
    echo ""
    echo "==> Terms accepted by operator. Initializing setup..."
    echo ""
    ;;
  *)
    echo ""
    echo "==> Installation aborted by operator. No changes were made."
    exit 0
    ;;
esac

# 3. Ensure 'dialog' is installed for interactive menus
if ! command -v dialog &> /dev/null; then
  echo "==> Installing 'dialog' utility for interactive configuration..."
  dnf install -y dialog
fi

# 4. Interactive Menu: System Language Selection
LANG_CHOICE=$(dialog --clear --backtitle "MaXX Interactive Desktop Setup - Rocky Linux 9" \
  --title "System Language Selection" \
  --menu "Select the default system language:" 15 60 5 \
  "1" "English (en_US.UTF-8)" \
  "2" "French (fr_FR.UTF-8)" \
  "3" "German (de_DE.UTF-8)" \
  "4" "Italian (it_IT.UTF-8)" \
  "5" "Spanish (es_ES.UTF-8)" \
  2>&1 >/dev/tty) || { clear; echo "Error: Language selection cancelled by operator. Exiting."; exit 1; }

case "$LANG_CHOICE" in
  1) SYS_LOCALE="en_US.UTF-8"; LANGPACK="glibc-langpack-en" ;;
  2) SYS_LOCALE="fr_FR.UTF-8"; LANGPACK="glibc-langpack-fr" ;;
  3) SYS_LOCALE="de_DE.UTF-8"; LANGPACK="glibc-langpack-de" ;;
  4) SYS_LOCALE="it_IT.UTF-8"; LANGPACK="glibc-langpack-it" ;;
  5) SYS_LOCALE="es_ES.UTF-8"; LANGPACK="glibc-langpack-es" ;;
esac

# 5. Interactive Menu: Keyboard Layout Selection
KB_CHOICE=$(dialog --clear --backtitle "MaXX Interactive Desktop Setup - Rocky Linux 9" \
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
  2>&1 >/dev/tty) || { clear; echo "Error: Keyboard selection cancelled by operator. Exiting."; exit 1; }

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

clear

# 6. Start installation and system configuration process
echo "==> [1/7] Enabling CRB and EPEL repositories..."
dnf install -y dnf-plugins-core
dnf config-manager --set-enabled crb
dnf install -y epel-release
dnf update -y

echo "==> [2/7] Installing Xorg server, drivers, and SDDM..."
# Install a standalone X11 server without heavy desktop environments (GNOME/KDE)
dnf install -y \
  xorg-x11-server-Xorg \
  xorg-x11-xinit \
  xorg-x11-xauth \
  xorg-x11-drv-libinput \
  mesa-dri-drivers \
  mesa-vulkan-drivers \
  sddm \
  sddm-themes \
  dbus-x11 \
  polkit

echo "==> [3/7] Configuring System Locale and Keyboard Layouts (Console & X11)..."
# Install the appropriate language pack so the locale is properly generated
dnf install -y "$LANGPACK"
localectl set-locale LANG="$SYS_LOCALE"

# Configure console keymap
localectl set-keymap "$VC_KEYMAP"

# Configure X11 keymap (creates /etc/X11/xorg.conf.d/00-keyboard.conf)
if [ -n "$X11_VARIANT" ]; then
  localectl set-x11-keymap "$X11_LAYOUT" pc105 "$X11_VARIANT"
else
  localectl set-x11-keymap "$X11_LAYOUT" pc105
fi

echo "    -> Locale set to: $SYS_LOCALE"
echo "    -> Console keymap set to: $VC_KEYMAP"
echo "    -> X11 layout set to: $X11_LAYOUT ${X11_VARIANT:+(variant: $X11_VARIANT)}"

echo "==> [4/7] Installing MaXX Desktop dependencies and utilities..."
dnf install -y \
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
  gtk3

echo "==> [5/7] Installing X11 (Bitmap/ISO8859-1) and TrueType fonts..."
dnf install -y \
  xorg-x11-fonts-misc \
  xorg-x11-fonts-75dpi \
  xorg-x11-fonts-ISO8859-1-75dpi \
  xorg-x11-fonts-100dpi \
  xorg-x11-fonts-ISO8859-1-100dpi \
  dejavu-sans-mono-fonts \
  google-noto-fonts-common \
  google-noto-sans-fonts \
  google-noto-mono-fonts \
  google-noto-sans-ui-fonts

# bitmap-fonts-compat may be missing depending on EL9 mirror status
dnf install -y bitmap-fonts-compat || echo "Info: bitmap-fonts-compat skipped (not found in repository)."

echo "==> [6/7] Downloading and installing MaXX Interactive Desktop..."
MAXX_URL="https://s3.ca-central-1.amazonaws.com/cdn.maxxinteractive.com/maxx-desktop-installer/MaXX-Desktop-LINUX-x86_64-2.2.0-Installer.sh"
INSTALLER="/tmp/MaXX-Desktop-LINUX-x86_64-2.2.0-Installer.sh"

# Backup existing installation if present
if [ -d "/opt/MaXX" ]; then
  BACKUP_DIR="/opt/MaXX-backup-$(date +%s)"
  echo "Previous installation detected: moving to $BACKUP_DIR"
  mv /opt/MaXX "$BACKUP_DIR"
  rm -rf /usr/share/themes/{IndigoMagic,Rio,Gotham,MaXX*}
fi

cd /tmp
wget -q --show-progress -O "$INSTALLER" "$MAXX_URL"
chmod a+x "$INSTALLER"

# Run the official MaXX installer
"$INSTALLER"

echo "==> [7/7] Configuring SDDM and graphical boot target..."
# Ensure the MaXX XSession desktop entry is registered for SDDM
mkdir -p /usr/share/xsessions
if [ ! -f /usr/share/xsessions/maxx.desktop ] && [ -f /opt/MaXX/share/xsessions/maxx.desktop ]; then
  cp /opt/MaXX/share/xsessions/maxx.desktop /usr/share/xsessions/
fi

# Enable SDDM service and switch default target to graphical
systemctl enable sddm --force
systemctl set-default graphical.target

echo "================================================================================"
echo " Installation completed successfully!"
echo "   - System Language : $SYS_LOCALE"
echo "   - X11 Keyboard    : $X11_LAYOUT ${X11_VARIANT:+($X11_VARIANT)}"
echo ""
echo " Reboot the system using the command: reboot"
echo " On the SDDM login screen, select 'MaXX Interactive Desktop' in the Session menu."
echo "================================================================================"