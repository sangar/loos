#!/bin/bash
# Install AUR helper (yay or paru) for installing AUR packages like walker
# This is optional - walker can also be built from source

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)

echo "Checking for AUR helper..."

# Check if yay or paru is already installed
if command -v yay &>/dev/null; then
  echo "yay already installed"
  exit 0
elif command -v paru &>/dev/null; then
  echo "paru already installed"
  exit 0
fi

# No AUR helper found, install yay
echo "Installing yay AUR helper..."

# Create temporary build directory
local BUILD_DIR=$(mktemp -d)
cd "$BUILD_DIR"

# Install dependencies
loos-pkg-add git base-devel

# Clone and build yay
git clone https://aur.archlinux.org/yay.git
cd yay

# Build without installing (we'll use it to install walker)
makepkg -si --noconfirm

# Cleanup
cd /
rm -rf "$BUILD_DIR"

echo "yay AUR helper installed successfully!"
