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

echo "Setting up AGS (Aylur's GTK Shell) v3..."
echo "This replaces Waybar for better fractional scaling support."
echo ""

# Install AGS and Astal libraries from AUR
echo "Installing AGS and Astal libraries from AUR..."
echo "Required packages:"
echo "  - $AGS_PACKAGE (AGS CLI tool)"
for pkg in "${ASTAL_PACKAGES[@]}"; do
    echo "  - $pkg"
done
echo ""

# Check if paru or yay is available for AUR
AUR_HELPER=""
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
fi

# Install packages
install_aur_package() {
    local pkg=$1
    if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
        echo "Installing $pkg from AUR..."
        if [[ -n "$AUR_HELPER" ]]; then
            $AUR_HELPER -S --noconfirm --needed "$pkg"
        else
            echo "Warning: No AUR helper found (paru/yay). Please install manually:"
            echo "  $pkg"
            return 1
        fi
    else
        echo "$pkg is already installed"
    fi
}

# Install main AGS package
install_aur_package "$AGS_PACKAGE"

# Install Astal libraries
for pkg in "${ASTAL_PACKAGES[@]}"; do
    install_aur_package "$pkg" || true
done

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
echo "AGS configured successfully!"
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
echo "To start AGS:"
echo "  ags &"
echo ""
echo "To restart AGS:"
echo "  ags quit && ags &"
echo ""
echo "Configuration location: $AGS_DIR"
echo ""

# Check if we're running in a graphical session
if [[ -n "$WAYLAND_DISPLAY" ]] || [[ -n "$DISPLAY" ]]; then
    echo "Note: AGS will start automatically on next Hyprland login."
else
    echo "Note: AGS requires a graphical session to run."
fi
