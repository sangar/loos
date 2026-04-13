#!/bin/bash
# Waybar configuration setup with GTK4 build from source
# This provides fractional scaling support on Wayland

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
WAYBAR_DIR="$USER_HOME/.config/waybar"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Waybar Setup (GTK4 Build)${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "Building Waybar from source with GTK4 for fractional scaling support."
echo ""

# Ensure sudo is available
if ! sudo -n true 2>/dev/null; then
  echo "Refreshing sudo credentials..."
  sudo -v
fi

# Install build dependencies
echo "Installing build dependencies..."
sudo pacman -S --noconfirm --needed base-devel git meson ninja pkg-config gtk4 gtk4-layer-shell \
  wayland wayland-protocols libsigc++-3.0 libfmt spdlog jack2 libpulse libsndio \
  libmpdclient libevdev upower libdbusmenu-gtk4 libxkbcommon wireplumber \
  libnl polkit gtkmm-4.0 || {
  echo -e "${YELLOW}Warning: Some dependencies may have failed, continuing...${NC}"
}

# Check if waybar is already installed and remove it
if command -v waybar &>/dev/null; then
  echo "Removing existing Waybar installation..."
  sudo pacman -R --noconfirm waybar 2>/dev/null || true
fi

# Create temp directory for building
TEMP_DIR=$(mktemp -d)
ORIGINAL_DIR=$(pwd)
cd "$TEMP_DIR"

echo ""
echo "Cloning Waybar repository..."
git clone --depth 1 https://github.com/Alexays/Waybar.git || {
  echo -e "${RED}Failed to clone Waybar repository${NC}"
  cd "$ORIGINAL_DIR"
  rm -rf "$TEMP_DIR"
  exit 1
}

cd Waybar

echo ""
echo "Configuring build with GTK4..."
meson setup build \
  --buildtype=release \
  --prefix=/usr \
  -Dgtkmm-4-0=enabled \
  -Dexperimental=true \
  -Dcava=disabled \
  -Dmpd=disabled || {
  echo -e "${RED}Meson setup failed${NC}"
  cd "$ORIGINAL_DIR"
  rm -rf "$TEMP_DIR"
  exit 1
}

echo ""
echo "Building Waybar (this may take a few minutes)..."
ninja -C build || {
  echo -e "${RED}Build failed${NC}"
  cd "$ORIGINAL_DIR"
  rm -rf "$TEMP_DIR"
  exit 1
}

echo ""
echo "Installing Waybar..."
sudo ninja -C build install || {
  echo -e "${RED}Installation failed${NC}"
  cd "$ORIGINAL_DIR"
  rm -rf "$TEMP_DIR"
  exit 1
}

# Cleanup
cd "$ORIGINAL_DIR"
rm -rf "$TEMP_DIR"

# Verify installation
if ! command -v waybar &>/dev/null; then
  echo -e "${RED}Waybar installation verification failed${NC}"
  exit 1
fi

echo -e "${GREEN}Waybar built and installed successfully!${NC}"
echo ""

# Create waybar config directory
mkdir -p "$WAYBAR_DIR"

# Copy base waybar config from loos
if [[ -d "$LOOS_PATH/config/waybar" ]]; then
  echo "Copying Waybar configuration..."
  cp -f "$LOOS_PATH/config/waybar/config" "$WAYBAR_DIR/config" 2>/dev/null || true
  cp -f "$LOOS_PATH/config/waybar/style.css" "$WAYBAR_DIR/style.css" 2>/dev/null || true
fi

# Create launcher script
cat >"$WAYBAR_DIR/launcher.sh" <<'EOF'
#!/bin/bash
# Rofi application launcher
rofi -show drun
EOF

chmod +x "$WAYBAR_DIR/launcher.sh"
chown -R "$USER:$USER" "$WAYBAR_DIR"

echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Waybar configured successfully!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Build: GTK4 with fractional scaling support"
echo ""
echo "Modules enabled:"
echo "  Left:   Workspaces, Window title"
echo "  Center: Clock"
echo "  Right:  Audio, Network, Battery, System tray"
echo ""
echo "Commands:"
echo "  Start Waybar:   waybar &"
echo "  Stop Waybar:    pkill waybar"
echo ""
echo "Configuration: $WAYBAR_DIR"
echo ""

# Check if we're in a graphical session
if [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ -n "${DISPLAY:-}" ]]; then
  echo -e "${BLUE}Note:${NC} Waybar will start automatically on next Hyprland login."
else
  echo -e "${BLUE}Note:${NC} Waybar requires a graphical session to run."
fi
