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

# Keep sudo alive throughout the installation
sudo -v
while true; do sudo -n true; sleep 60; done &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null || true" EXIT

# Update package database and install git (avoid full system upgrade to prevent kernel panic)
sudo pacman -Syy --noconfirm &>/dev/null || true
# Update keyring first to avoid signature issues, then install git
sudo pacman -S --noconfirm --needed archlinux-keyring &>/dev/null || true
sudo pacman -S --noconfirm --needed --overwrite '*' git

echo -e "\nCloning loOS from https://github.com/sangar/loos.git"
if [ -d ~/.local/share/loos ]; then
  echo "Removing existing loOS installation..."
fi
rm -fr ~/.local/share/loos/
git clone "https://github.com/sangar/loos.git" ~/.local/share/loos >/dev/null

echo -e "\nInstallation starting..."
source ~/.local/share/loos/install.sh
