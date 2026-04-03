#!/bin/bash

# print ascii logo
cat <<'EOF'
 _            ____   _____
| |          / __ \ / ____|
| |      ___| |  | | (___
| |     / _ \ |  | |\___ \
| |____|  L | |__| |  __) |
|______|\___/\____/|_____/

EOF

# Ensure sudo is installed and user has sudo access
if ! command -v sudo &>/dev/null; then
  echo "sudo not found. Installing..."
  su -c "pacman -S --noconfirm --needed --disable-sandbox-filesystem --disable-sandbox-syscalls sudo"
fi

# Add user to wheel group if not already
if ! groups "$USER" | grep -q "\bwheel\b"; then
  echo "Adding $USER to wheel group..."
  su -c "usermod -aG wheel $USER"
  echo "Please log out and back in for group changes, then re-run this script."
  exit 1
fi

# Update packages first
sudo pacman -Syu --noconfirm --needed --disable-sandbox-filesystem --disable-sandbox-syscalls git

echo -e "\nCloning loOS from https://github.com/sangar/loos.git"
rm -fr ~/.local/share/loos/
git clone "https://github.com/sangar/loos.git" ~/.local/share/loos >/dev/null

echo -e "\nInstallation starting..."
source ~/.local/share/loos/install.sh
