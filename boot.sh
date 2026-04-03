#!/bin/bash

# install: curl -sSL https://raw.githubusercontent.com/sangar/loos/master/boot.sh | bash

# print ascii logo
cat <<'EOF'
 _            ____   _____
| |          / __ \ / ____|
| |      ___| |  | | (___
| |     / _ \ |  | |\___ \
| |____|  L | |__| |  __) |
|______|\___/\____/|_____/

EOF

# Ensure sudo is installed and configured
if ! command -v sudo &>/dev/null || ! sudo true 2>/dev/null; then
  echo -e "\033[33mSudo not installed or not configured. Downloading bootstrap script...\033[0m" >&2

  # Download sudo.sh bootstrap script
  BOOTSTRAP_URL="https://raw.githubusercontent.com/sangar/loos/master/install/sudo.sh"
  curl -fsSL "$BOOTSTRAP_URL" -o /tmp/loos-sudo.sh 2>/dev/null || {
    echo -e "\033[31mError: Could not download bootstrap script.\033[0m" >&2
    echo "" >&2
    echo "Please install sudo manually:" >&2
    echo "  su -" >&2
    echo "  pacman -S sudo" >&2
    echo "  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers" >&2
    echo "  usermod -aG wheel $USER" >&2
    exit 1
  }

  chmod +x /tmp/loos-sudo.sh

  echo "" >&2
  echo "To install sudo, run the bootstrap script as root:" >&2
  echo "  su -c \"/tmp/loos-sudo.sh $USER\"" >&2
  echo "" >&2
  echo "Then log out and back in, and re-run this script." >&2
  exit 1
fi

# Update package database and install git (avoid full system upgrade to prevent kernel panic)
sudo pacman -Syy --noconfirm --disable-sandbox-filesystem --disable-sandbox-syscalls &>/dev/null || true
# Update keyring first to avoid signature issues, then install git
sudo pacman -S --noconfirm --needed --disable-sandbox-filesystem --disable-sandbox-syscalls archlinux-keyring &>/dev/null || true
sudo pacman -S --noconfirm --needed --disable-sandbox-filesystem --disable-sandbox-syscalls --overwrite '*' git

echo -e "\nCloning loOS from https://github.com/sangar/loos.git"
if [ -d ~/.local/share/loos ]; then
  echo "Removing existing loOS installation..."
fi
rm -fr ~/.local/share/loos/
git clone "https://github.com/sangar/loos.git" ~/.local/share/loos >/dev/null

echo -e "\nInstallation starting..."
source ~/.local/share/loos/install.sh
