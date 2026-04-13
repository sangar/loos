#!/bin/bash
# AGS (Aylur's GTK Shell) v3 configuration setup
# GTK4-based status bar with fractional scaling support
# Replaces Waybar for better HiDPI support on Wayland

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
LOOS_DEFAULT="$USER_HOME/.local/share/loos/default"
AGS_DIR="$USER_HOME/.config/ags"

# AGS package is aylurs-gtk-shell (v3.1.2+) - AUR package
AGS_PACKAGE="aylurs-gtk-shell"

# Astal libraries required for bar functionality
ASTAL_PACKAGES=(
  "libastal-4-git"           # GTK4 core
  "libastal-hyprland-git"    # Hyprland IPC
  "libastal-wireplumber-git" # Audio control
  "libastal-network-git"     # NetworkManager
  "libastal-battery-git"     # Battery status
  "libastal-tray-git"        # System tray
  "libastal-gjs-git"         # GJS bindings (for TypeScript/JavaScript)
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  AGS (Aylur's GTK Shell) v3 Setup${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "This replaces Waybar for better fractional scaling support."
echo ""

# Check which AUR helper is available (paru is installed by preflight)
AUR_HELPER=""
if command -v paru &>/dev/null; then
  AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
  AUR_HELPER="yay"
fi

# Fallback: if no AUR helper, try to install paru one more time
if [[ -z "$AUR_HELPER" ]]; then
  echo -e "${YELLOW}AUR helper not found. Attempting to install paru...${NC}"

  # Check for required build dependencies
  build_deps=("base-devel" "git")
  for dep in "${build_deps[@]}"; do
    if ! pacman -Q "$dep" &>/dev/null 2>&1; then
      echo "Installing build dependency: $dep"
      sudo pacman -S --noconfirm --needed "$dep" || exit 1
    fi
  done

  # Install rust if not present
  if ! command -v cargo &>/dev/null; then
    echo "Installing rust..."
    sudo pacman -S --noconfirm --needed rust || exit 1
  fi

  # Build paru
  temp_dir=$(mktemp -d)
  original_dir=$(pwd)
  cd "$temp_dir"

  echo "Cloning paru repository..."
  git clone https://aur.archlinux.org/paru.git || exit 1
  cd paru

  echo "Building paru..."
  makepkg -si --noconfirm || exit 1

  cd "$original_dir"
  rm -rf "$temp_dir"

  AUR_HELPER="paru"
  echo -e "${GREEN}paru installed successfully!${NC}"
fi

# Install packages from AUR
install_aur_package() {
  local pkg=$1

  if pacman -Q "$pkg" &>/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $pkg is already installed"
    return 0
  fi

  echo "Installing $pkg from AUR..."
  $AUR_HELPER -S --noconfirm --needed "$pkg" || {
    echo -e "${RED}Failed to install $pkg${NC}"
    return 1
  }
}

# Show required packages
echo "Required AUR packages:"
echo "  Core: $AGS_PACKAGE"
for pkg in "${ASTAL_PACKAGES[@]}"; do
  echo "  Lib:  $pkg"
done
echo ""
echo "Using AUR helper: $AUR_HELPER"
echo ""

# Check which packages need to be installed
MISSING_PACKAGES=()

if ! pacman -Q "$AGS_PACKAGE" &>/dev/null 2>&1; then
  MISSING_PACKAGES+=("$AGS_PACKAGE")
fi

for pkg in "${ASTAL_PACKAGES[@]}"; do
  if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
    MISSING_PACKAGES+=("$pkg")
  fi
done

if [[ ${#MISSING_PACKAGES[@]} -eq 0 ]]; then
  echo -e "${GREEN}All AGS packages are already installed!${NC}"
else
  echo "Missing packages: ${#MISSING_PACKAGES[@]}"
  echo ""
  echo "Installing packages automatically..."
  echo ""

  for pkg in "${MISSING_PACKAGES[@]}"; do
    install_aur_package "$pkg" || {
      echo -e "${RED}Error: Failed to install $pkg${NC}"
      echo "Installation aborted."
      exit 1
    }
  done
fi

echo ""
echo "Creating AGS configuration directory..."
mkdir -p "$AGS_DIR"

# Copy AGS configs from loos
if [[ -d "$LOOS_PATH/config/ags" ]]; then
  echo "Copying AGS configuration..."
  cp -f "$LOOS_PATH/config/ags/config.js" "$AGS_DIR/config.js" 2>/dev/null || true
  cp -f "$LOOS_PATH/config/ags/style.css" "$AGS_DIR/style.css" 2>/dev/null || true
fi

# Set proper ownership
chown -R "$USER:$USER" "$AGS_DIR" 2>/dev/null || true

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  AGS configured successfully!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Modules enabled:"
echo "  Left:   Workspaces, Window title"
echo "  Center: Clock"
echo "  Right:  Audio, Network, Battery, System tray"
echo ""
echo "Features:"
echo "  - GTK4 native (fractional scaling support)"
echo "  - TypeScript/GJS based configuration"
echo "  - Clickable widgets with tooltips"
echo ""
echo "Commands:"
echo "  Start AGS:    ags &"
echo "  Restart AGS:  ags quit && ags &"
echo "  Stop AGS:     ags quit"
echo ""
echo "Configuration location: $AGS_DIR"
echo ""

# Check if we're running in a graphical session
if [[ -n "$WAYLAND_DISPLAY" ]] || [[ -n "$DISPLAY" ]]; then
  echo -e "${BLUE}Note:${NC} AGS will start automatically on next Hyprland login."
else
  echo -e "${BLUE}Note:${NC} AGS requires a graphical session to run."
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
