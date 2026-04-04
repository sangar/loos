#!/bin/bash

# install_sudo.sh - Install and configure sudo on Arch Linux ARM
# Usage as root: su -c "./install/sudo.sh <username>"
# Or: su -c "./install/sudo.sh $USER"

set -e

TARGET_USER="${1:-$SUDO_USER}"
TARGET_USER="${TARGET_USER:-$USER}"

if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "Error: Please specify a non-root username to add to wheel group" >&2
  echo "Usage: su -c \"$0 <username>\"" >&2
  exit 1
fi

echo "=== Step 1: Disable sandbox (avoids Landlock issue) ==="
if ! grep -q "^DisableSandbox$" /etc/pacman.conf; then
  sed -i '/^\[options\]/a DisableSandbox' /etc/pacman.conf
fi

echo
echo "=== Step 2: pacman init"
su -c "pacman-key --init && pacman-key --populate archlinuxarm"

echo ""
echo "=== Step 3: Update the system ==="
pacman -Syu --noconfirm

echo ""
echo "=== Step 4: Install sudo ==="
pacman -S sudo --noconfirm

echo ""
echo "=== Step 5: Enable wheel group in sudoers ==="
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo ""
echo "=== Step 6: Add $TARGET_USER to wheel group ==="
usermod -aG wheel "$TARGET_USER"

echo ""
echo "=== Setup complete ==="
echo "Log out and back in, then test with: sudo whoami"
