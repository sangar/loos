#!/bin/bash
# Install AUR helper (paru) if not present
# Required for AGS and other AUR packages

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check if paru or yay is available
check_aur_helper() {
  if command -v paru &>/dev/null; then
    echo "paru"
  elif command -v yay &>/dev/null; then
    echo "yay"
  else
    echo ""
  fi
}

AUR_HELPER=$(check_aur_helper)

# Install paru automatically if no AUR helper exists
install_paru() {
  echo -e "${YELLOW}Installing paru AUR helper...${NC}"

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

  # Install rust if not present
  if ! command -v cargo &>/dev/null; then
    echo "Installing rust..."
    sudo pacman -S --noconfirm --needed rust || {
      echo -e "${RED}Failed to install rust${NC}"
      exit 1
    }
  fi

  # Create temp directory for building
  local temp_dir=$(mktemp -d)
  local original_dir=$(pwd)
  cd "$temp_dir"

  echo "Cloning paru repository..."
  git clone https://aur.archlinux.org/paru.git || {
    echo -e "${RED}Failed to clone paru repository${NC}"
    cd "$original_dir"
    rm -rf "$temp_dir"
    exit 1
  }

  cd paru

  echo "Building paru (this may take a few minutes)..."
  makepkg -si --noconfirm || {
    echo -e "${RED}Failed to build paru${NC}"
    cd "$original_dir"
    rm -rf "$temp_dir"
    exit 1
  }

  cd "$original_dir"
  rm -rf "$temp_dir"

  if command -v paru &>/dev/null; then
    echo -e "${GREEN}paru installed successfully!${NC}"
  else
    echo -e "${RED}paru installation failed${NC}"
    exit 1
  fi
}

# Main
if [[ -z "$AUR_HELPER" ]]; then
  echo "AUR helper not found. Installing paru..."
  install_paru
else
  echo "Using AUR helper: $AUR_HELPER"
fi
