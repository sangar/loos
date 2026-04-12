#!/bin/bash
# loOS Uninstall Script
# Removes loOS configuration, packages, and optionally user data

set -eE

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
LOOS_PATH="${HOME}/.local/share/loos"
LOOS_CONFIG="${HOME}/.config/loos"
LOOS_BIN="${HOME}/.local/bin"
USER_CONFIG="${HOME}/.config"

# Load package list from loos-base.packages (if available)
# or use the installed copy
PKG_LIST_FILE=""
if [[ -f "${LOOS_PATH}/install/loos-base.packages" ]]; then
    PKG_LIST_FILE="${LOOS_PATH}/install/loos-base.packages"
elif [[ -f "./install/loos-base.packages" ]]; then
    # Running from loos directory
    PKG_LIST_FILE="./install/loos-base.packages"
elif [[ -f "${HOME}/loos/install/loos-base.packages" ]]; then
    PKG_LIST_FILE="${HOME}/loos/install/loos-base.packages"
fi

# Read package list from file
if [[ -n "$PKG_LIST_FILE" ]] && [[ -f "$PKG_LIST_FILE" ]]; then
    # Read packages from file, skipping comments and empty lines
    LOOS_PACKAGES=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// /}" ]] && continue
        LOOS_PACKAGES+=("$line")
    done < "$PKG_LIST_FILE"
    echo "Loaded package list from: $PKG_LIST_FILE"
else
    # Fallback: hardcoded list if file not found
    echo "Warning: Could not find loos-base.packages, using fallback list" >&2
    LOOS_PACKAGES=(
        adwaita-icon-theme
        foot
        brightnessctl
        btop
        dunst
        fastfetch
        grim
        gvfs
        gtk3
        gtk4
        hyprland
        hyprpaper
        hyprpolkitagent
        libdisplay-info
        libqalculate
        lxappearance
        mesa
        mise
        network-manager-applet
        noto-fonts-emoji
        nvim
        pipewire
        playerctl
        polkit
        qt5-wayland
        seatd
        slurp
        sddm
        thunar
        ttf-jetbrains-mono-nerd
        uwsm
        rofi-wayland
        waybar
        wireplumber
        wl-clipboard
        xdg-desktop-portal
        xdg-desktop-portal-hyprland
    )
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}           loOS Uninstaller             ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will remove loOS configuration and optionally packages.${NC}"
echo ""
echo "What would you like to do?"
echo ""
echo "  1) Full uninstall - Remove configs AND packages (DANGEROUS)"
echo "  2) Remove loOS configs only - Keep packages (SAFE)"
echo "  3) Remove user configs too - Full cleanup (DESTRUCTIVE)"
echo "  4) Cancel - Do nothing"
echo ""
read -rp "Enter choice [1-4]: " choice

case "$choice" in
    1)
        MODE="full"
        echo -e "${RED}WARNING: This will remove loOS packages which may break your system!${NC}"
        read -rp "Are you sure? (type 'yes' to confirm): " confirm
        if [[ "$confirm" != "yes" ]]; then
            echo "Aborted."
            exit 0
        fi
        ;;
    2)
        MODE="configs-only"
        ;;
    3)
        MODE="destructive"
        echo -e "${RED}WARNING: This will remove ALL loOS-related user configurations!${NC}"
        read -rp "Are you sure? (type 'DESTROY' to confirm): " confirm
        if [[ "$confirm" != "DESTROY" ]]; then
            echo "Aborted."
            exit 0
        fi
        ;;
    4|*)
        echo "Cancelled. No changes made."
        exit 0
        ;;
esac

echo ""
echo -e "${BLUE}Starting uninstall...${NC}"
echo ""

# Function to remove with error handling
safe_remove() {
    local path="$1"
    if [[ -e "$path" ]] || [[ -L "$path" ]]; then
        echo -e "  ${YELLOW}Removing:${NC} $path"
        rm -rf "$path" 2>/dev/null || {
            echo -e "    ${RED}Failed to remove (may need sudo)${NC}"
            return 1
        }
    fi
}

# Stop and disable user services
echo -e "${BLUE}Stopping loOS services...${NC}"
systemctl --user stop xdg-desktop-portal.service 2>/dev/null || true
systemctl --user stop hyprpolkitagent.service 2>/dev/null || true
systemctl --user disable xdg-desktop-portal.service 2>/dev/null || true
systemctl --user disable hyprpolkitagent.service 2>/dev/null || true

# Remove systemd user units
echo -e "${BLUE}Removing systemd units...${NC}"
safe_remove "$USER_CONFIG/systemd/user/loos-*"
safe_remove "$USER_CONFIG/systemd/user/xdg-desktop-portal.service"
safe_remove "$USER_CONFIG/systemd/user/hyprpolkitagent.service"

# Remove loOS binary symlinks
echo -e "${BLUE}Removing loOS binaries...${NC}"
for binary in loos-pkg-add loos-pkg-missing loos-pkg-download loos-theme loos-wallpaper loos-background loos-theme-apply-on-login loos-keyboard-sync loos-refresh-hypr loos-refresh-sddm loos-waybar-debug loos-npx-install; do
    safe_remove "$LOOS_BIN/$binary"
done

# Remove loOS installation directory
echo -e "${BLUE}Removing loOS installation...${NC}"
safe_remove "$LOOS_PATH"

# Remove loOS config directory
echo -e "${BLUE}Removing loOS config state...${NC}"
safe_remove "$LOOS_CONFIG"

# Remove application configs installed by loOS
echo -e "${BLUE}Removing application configs...${NC}"
safe_remove "$USER_CONFIG/hypr"  # Hyprland configs
safe_remove "$USER_CONFIG/waybar"
safe_remove "$USER_CONFIG/rofi"
safe_remove "$USER_CONFIG/foot"
safe_remove "$USER_CONFIG/btop"
safe_remove "$USER_CONFIG/fastfetch"
safe_remove "$USER_CONFIG/dunst"
safe_remove "$USER_CONFIG/loos"  # if exists

# Remove wallpapers
echo -e "${BLUE}Removing loOS wallpapers...${NC}"
safe_remove "${HOME}/.local/share/loos"

# Remove from .bashrc if present
echo -e "${BLUE}Cleaning up .bashrc...${NC}"
if [[ -f "${HOME}/.bashrc" ]]; then
    # Remove loOS-specific lines
    sed -i '/# loOS/d' "${HOME}/.bashrc" 2>/dev/null || true
    sed -i '/fastfetch/d' "${HOME}/.bashrc" 2>/dev/null || true
fi

# Remove from environment.d
echo -e "${BLUE}Cleaning up environment.d...${NC}"
safe_remove "$USER_CONFIG/environment.d/99-pi5.conf" 2>/dev/null || true

# Full destructive mode - remove more
if [[ "$MODE" == "destructive" ]]; then
    echo -e "${RED}Destructive mode: Removing additional configs...${NC}"
    
    # Remove NVim config (if installed by loOS)
    read -rp "Remove Neovim config? [y/N]: " remove_nvim
    if [[ "$remove_nvim" =~ ^[Yy]$ ]]; then
        safe_remove "$USER_CONFIG/nvim"
        safe_remove "${HOME}/.local/share/nvim"
        safe_remove "${HOME}/.local/state/nvim"
    fi
    
    # Remove mise and installed tools
    read -rp "Remove mise and global tools (node, rust)? [y/N]: " remove_mise
    if [[ "$remove_mise" =~ ^[Yy]$ ]]; then
        safe_remove "${HOME}/.local/share/mise"
        safe_remove "$USER_CONFIG/mise"
        # Remove from .bashrc
        sed -i '/mise activate/d' "${HOME}/.bashrc" 2>/dev/null || true
    fi
    
    # Remove all cached wallpapers and thumbnails
    safe_remove "${HOME}/.cache/loos"
fi

# Remove packages (only in full mode)
if [[ "$MODE" == "full" ]]; then
    echo ""
    echo -e "${RED}Removing packages...${NC}"
    echo "The following packages will be removed (${#LOOS_PACKAGES[@]} total):"
    printf '  %s\n' "${LOOS_PACKAGES[@]}"
    echo ""
    read -rp "Continue? (type 'REMOVE' to confirm): " confirm
    
    if [[ "$confirm" == "REMOVE" ]]; then
        # Try to remove packages
        if command -v pacman &>/dev/null; then
            echo -e "${YELLOW}Removing packages with pacman...${NC}"
            # Remove packages one by one to handle errors
            for pkg in "${LOOS_PACKAGES[@]}"; do
                if pacman -Q "$pkg" &>/dev/null 2>&1; then
                    echo "  Removing: $pkg"
                    sudo pacman -R --noconfirm "$pkg" 2>/dev/null || {
                        echo -e "    ${YELLOW}Could not remove $pkg (may be needed by other packages)${NC}"
                    }
                fi
            done
        fi
        
        echo ""
        echo -e "${YELLOW}Note: Some packages may remain if they're dependencies for other software.${NC}"
        echo -e "${YELLOW}To force remove: sudo pacman -Rdd <package>${NC}"
    else
        echo "Package removal cancelled."
    fi
fi

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}       loOS uninstall complete!           ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

if [[ "$MODE" == "full" ]] || [[ "$MODE" == "destructive" ]]; then
    echo -e "${YELLOW}Important:${NC}"
    echo "  - You may want to restore your pre-loOS configs from backups"
    echo "  - Hyprland may fail to start without a valid config"
    echo "  - Consider installing another DE/WM or restoring original configs"
    echo ""
    echo "To restore from backup (if available):"
    echo "  cp -r ~/.config/hypr.bak.* ~/.config/hypr/"
    echo ""
fi

echo -e "${BLUE}Remaining cleanup (optional):${NC}"
echo "  - Review and edit ~/.bashrc manually if needed"
echo "  - Check for remaining entries in ~/.profile or ~/.zshrc"
echo "  - Remove cached packages: sudo pacman -Sc"
echo ""
echo -e "${GREEN}Thank you for trying loOS!${NC}"
