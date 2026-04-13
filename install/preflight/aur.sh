#!/bin/bash
# Install AUR helper (yay) if not present
# Required for AGS and other AUR packages

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check if paru or yay is available
check_aur_helper() {
  if command -v yay &>/dev/null; then
    echo "yay"
  elif command -v paru &>/dev/null; then
    echo "paru"
  else
    echo ""
  fi
}

AUR_HELPER=$(check_aur_helper)

# Ensure sudo is available and credentials are fresh
ensure_sudo() {
  # Check if we can run sudo without password (or with cached credentials)
  if ! sudo -n true 2>/dev/null; then
    echo "Refreshing sudo credentials..."
    sudo -v
  fi
}

# Install yay automatically if no AUR helper exists
install_yay() {
  echo -e "${YELLOW}Installing yay AUR helper...${NC}"

  # Ensure sudo is ready
  ensure_sudo

  # Check for required build dependencies
  local build_deps=("base-devel" "git")
  for dep in "${build_deps[@]}"; do
    if ! pacman -Q "$dep" &>/dev/null 2>&1; then
      echo "Installing build dependency: $dep"
      sudo pacman -S --noconfirm --needed "$dep" || {
        echo -e "${RED}Failed to install $dep${NC}"
        exit 1
      }
    fi
  done

  # Install go if not present (required for yay)
  if ! command -v go &>/dev/null; then
    echo "Installing go (required for yay)..."
    ensure_sudo
    sudo pacman -S --noconfirm --needed go || {
      echo -e "${RED}Failed to install go${NC}"
      exit 1
    }
  fi

  # Create temp directory for building
  local temp_dir=$(mktemp -d)
  local original_dir=$(pwd)
  cd "$temp_dir"

  echo "Cloning yay repository..."
  git clone https://aur.archlinux.org/yay.git || {
    echo -e "${RED}Failed to clone yay repository${NC}"
    cd "$original_dir"
    rm -rf "$temp_dir"
    exit 1
  }

  cd yay

  echo "Building yay (this should be quick)..."
  # Build without installing first (avoids sudo timeout during build)
  makepkg -s --noconfirm || {
    echo -e "${RED}Failed to build yay${NC}"
    cd "$original_dir"
    rm -rf "$temp_dir"
    exit 1
  }

  # Now install the built package with explicit sudo
  echo "Installing built yay package..."
  ensure_sudo
  local pkg_file=$(ls yay-*.pkg.tar.zst 2>/dev/null | head -1)
  if [[ -n "$pkg_file" ]]; then
    sudo pacman -U --noconfirm "$pkg_file" || {
      echo -e "${RED}Failed to install yay package${NC}"
      cd "$original_dir"
      rm -rf "$temp_dir"
      exit 1
    }
  else
    echo -e "${RED}Could not find built package file${NC}"
    cd "$original_dir"
    rm -rf "$temp_dir"
    exit 1
  fi

  cd "$original_dir"
  rm -rf "$temp_dir"

  if command -v yay &>/dev/null; then
    echo -e "${GREEN}yay installed successfully!${NC}"
  else
    echo -e "${RED}yay installation failed${NC}"
    exit 1
  fi
}

# Main
if [[ -z "$AUR_HELPER" ]]; then
  echo "AUR helper not found. Installing yay..."
  install_yay
else
  echo "Using AUR helper: $AUR_HELPER"
fi
