#!/bin/bash
# Download all loOS packages without installing
# Use this to prepare a VM image before cloning
# When the clone boots, packages will already be in pacman cache
#
# Usage:
#   Local: ./prepare.sh
#   Remote: curl -sSL https://raw.githubusercontent.com/sangar/loos/master/prepare.sh | bash

set -eEo pipefail

# GitHub raw URL for loos files
LOOS_REPO="https://raw.githubusercontent.com/sangar/loos/master"

# Detect if running locally or via curl
# If BASH_SOURCE is a single file without path, we're likely running via curl
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
IS_REMOTE=false

if [[ "$SCRIPT_SOURCE" == "bash" ]] || [[ "$SCRIPT_SOURCE" == "/dev/stdin" ]] || [[ ! -f "$SCRIPT_SOURCE" ]]; then
  IS_REMOTE=true
  echo "=========================================="
  echo " loOS Remote Package Preparation"
  echo "=========================================="
  echo ""
  echo "Running remotely via curl..."
  echo "Downloading package list from GitHub..."
  echo ""
else
  echo "=========================================="
  echo " loOS Package Preparation (Download Only)"
  echo "=========================================="
  echo ""
fi

# Check if running as root or with sudo
if ! sudo -n true 2>/dev/null; then
  echo "Requesting sudo access for package download..."
  sudo -v
fi

# Get package list
if [[ "$IS_REMOTE" == true ]]; then
  # Download package list from GitHub
  PKG_LIST_URL="${LOOS_REPO}/install/loos-base.packages"
  PKG_LIST="/tmp/loos-base.packages"
  
  if ! curl -sSL "$PKG_LIST_URL" -o "$PKG_LIST"; then
    echo "Error: Failed to download package list from $PKG_LIST_URL" >&2
    exit 1
  fi
  echo "Downloaded package list from GitHub"
else
  # Get the directory where this script is located
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PKG_LIST="${SCRIPT_DIR}/install/loos-base.packages"
  
  if [[ ! -f "$PKG_LIST" ]]; then
    echo "Error: Package list not found at $PKG_LIST" >&2
    exit 1
  fi
fi

echo "Reading package list from: $PKG_LIST"
echo ""

# Create filter list for packages to skip (comments, empty lines)
# Also handle packages that might not exist in repos (AUR packages)
filter_packages() {
  grep -v '^#' "$PKG_LIST" | grep -v '^$' | grep -v '^[[:space:]]*$'
}

echo "Packages to download:"
echo "---------------------"
filter_packages
TOTAL=$(filter_packages | wc -l)
echo "---------------------"
echo "Total: $TOTAL packages"
echo ""

# Update package database
echo "Updating package database..."
sudo pacman -Syy

# Download packages without installing
echo ""
echo "Downloading packages to cache..."
echo "(Packages will be stored in /var/cache/pacman/pkg/)"
echo ""

# Download all packages at once for efficiency
# Using -Sw: S=sync, w=download only
if ! sudo pacman -Sw --noconfirm $(filter_packages); then
  echo ""
  echo -e "\033[33mWarning: Some packages may not be available in official repositories\033[0m" >&2
  echo "(AUR packages or custom packages will need to be built during install)" >&2
fi

echo ""
echo "=========================================="
echo " Download Complete!"
echo "=========================================="
echo ""
echo "Packages are cached in: /var/cache/pacman/pkg/"
echo ""

if [[ "$IS_REMOTE" == true ]]; then
  echo "You can now:"
  echo "  1. Clone this VM/image"
  echo "  2. Download and run install.sh on the clone:"
  echo "     curl -sSL ${LOOS_REPO}/install.sh | bash"
  echo "     OR clone the full repo: git clone https://github.com/sangar/loos.git"
  echo "  3. Installation will use cached packages (much faster!)"
else
  echo "You can now:"
  echo "  1. Clone this VM/image"
  echo "  2. Run ./install.sh on the clone"
  echo "  3. Installation will use cached packages (much faster!)"
fi

echo ""
echo "Cache size:"
du -sh /var/cache/pacman/pkg/ 2>/dev/null || echo "Unable to calculate"
echo ""

# Cleanup temp file if downloaded
if [[ "$IS_REMOTE" == true ]] && [[ -f "$PKG_LIST" ]]; then
  rm -f "$PKG_LIST"
fi
