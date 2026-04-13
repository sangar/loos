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

# Check if paru or yay is available for AUR
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

# Function to install paru if no AUR helper exists
install_paru() {
  echo -e "${YELLOW}No AUR helper found. Installing paru...${NC}"
  echo ""

  # Check for required build dependencies
  local build_deps=("base-devel" "git" "rust")
  for dep in "${build_deps[@]}"; do
    if ! pacman -Q "$dep" &>/dev/null 2>&1; then
      echo "Installing build dependency: $dep"
      sudo pacman -S --noconfirm --needed "$dep" || {
        echo -e "${RED}Failed to install $dep${NC}"
        return 1
      }
    fi
  done

  # Create temp directory for building
  local temp_dir=$(mktemp -d)
  cd "$temp_dir"

  echo "Cloning paru repository..."
  git clone https://aur.archlinux.org/paru.git
  cd paru

  echo "Building paru..."
  makepkg -si --noconfirm

  local result=$?
  cd "$HOME"
  rm -rf "$temp_dir"

  if [[ $result -eq 0 ]]; then
    echo -e "${GREEN}paru installed successfully!${NC}"
    AUR_HELPER="paru"
    return 0
  else
    echo -e "${RED}Failed to install paru${NC}"
    return 1
  fi
}

# Install packages from AUR
install_aur_package() {
  local pkg=$1

  if pacman -Q "$pkg" &>/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} $pkg is already installed"
    return 0
  fi

  if [[ -n "$AUR_HELPER" ]]; then
    echo "Installing $pkg from AUR..."
    $AUR_HELPER -S --noconfirm --needed "$pkg" || {
      echo -e "${RED}Failed to install $pkg${NC}"
      return 1
    }
  else
    return 1
  fi
}

# Show required packages
echo "Required AUR packages:"
echo "  Core: $AGS_PACKAGE"
for pkg in "${ASTAL_PACKAGES[@]}"; do
  echo "  Lib:  $pkg"
done
echo ""

# Try to install packages
MISSING_PACKAGES=()

# Check which packages are missing
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
  echo -e "${YELLOW}Missing packages: ${#MISSING_PACKAGES[@]}${NC}"
  echo ""

  if [[ -z "$AUR_HELPER" ]]; then
    echo -e "${YELLOW}No AUR helper found (paru/yay).${NC}"
    echo ""
    echo "Would you like to:"
    echo "  1) Install paru (AUR helper) automatically"
    echo "  2) Show manual installation instructions"
    echo "  3) Skip AGS installation"
    echo ""
    read -rp "Enter choice [1-3]: " choice

    case $choice in
    1)
      if ! install_paru; then
        echo -e "${RED}Failed to install paru. Please install manually.${NC}"
        echo ""
        echo "Manual installation instructions:"
        echo "  git clone https://aur.archlinux.org/paru.git"
        echo "  cd paru && makepkg -si"
        echo ""
        exit 1
      fi
      ;;
    2)
      echo ""
      echo "==========================================="
      echo "MANUAL INSTALLATION INSTRUCTIONS"
      echo "==========================================="
      echo ""
      echo "Option 1: Install an AUR helper first:"
      echo "  # Install paru (recommended):"
      echo "  sudo pacman -S --needed base-devel rust"
      echo "  git clone https://aur.archlinux.org/paru.git"
      echo "  cd paru && makepkg -si"
      echo ""
      echo "  # Or install yay:"
      echo "  sudo pacman -S --needed base-devel git"
      echo "  git clone https://aur.archlinux.org/yay.git"
      echo "  cd yay && makepkg -si"
      echo ""
      echo "Option 2: Install AGS packages manually:"
      echo "  # Download and build each package:"
      for pkg in "$AGS_PACKAGE" "${ASTAL_PACKAGES[@]}"; do
        echo "  git clone https://aur.archlinux.org/$pkg.git"
        echo "  cd $pkg && makepkg -si"
        echo "  cd .."
      done
      echo ""
      echo "Then re-run this script."
      echo ""
      exit 0
      ;;
    3)
      echo "Skipping AGS installation."
      echo "Note: loOS will not have a status bar until AGS is installed."
      exit 0
      ;;
    *)
      echo "Invalid choice. Skipping AGS installation."
      exit 0
      ;;
    esac
  fi

  # Install all missing packages
  echo ""
  echo "Installing missing packages..."
  echo ""

  for pkg in "${MISSING_PACKAGES[@]}"; do
    install_aur_package "$pkg" || {
      echo -e "${RED}Failed to install $pkg${NC}"
      echo "You may need to install it manually."
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
