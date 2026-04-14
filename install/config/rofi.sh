#!/bin/bash
# Rofi-wayland launcher configuration setup

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
ROFI_DIR="$USER_HOME/.config/rofi"

# Support both environment variable and fallback to script location
if [[ -z "${LOOS_PATH:-}" ]]; then
  # Try to determine LOOS_PATH from script location
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ "$SCRIPT_DIR" == */install/config ]]; then
    LOOS_PATH="$(dirname "$(dirname "$SCRIPT_DIR")")"
  elif [[ -d "$HOME/.local/share/loos" ]]; then
    LOOS_PATH="$HOME/.local/share/loos"
  elif [[ -d "/home/$USER/.local/share/loos" ]]; then
    LOOS_PATH="/home/$USER/.local/share/loos"
  else
    echo "Warning: LOOS_PATH not set and cannot determine location"
    echo "Rofi configs may not be copied correctly"
  fi
fi

echo "Setting up Rofi launcher..."

# Ensure rofi config directory exists
mkdir -p "$ROFI_DIR"

# Copy rofi configs from loos
if [[ -f "${LOOS_PATH}/config/rofi/config.rasi" ]]; then
  echo "Copying rofi config..."
  cp -f "${LOOS_PATH}/config/rofi/config.rasi" "$ROFI_DIR/config.rasi" 2>/dev/null || {
    echo "Warning: Failed to copy config.rasi"
  }
fi

if [[ -f "${LOOS_PATH}/config/rofi/theme.rasi" ]]; then
  cp -f "${LOOS_PATH}/config/rofi/theme.rasi" "$ROFI_DIR/theme.rasi" 2>/dev/null || {
    echo "Warning: Failed to copy theme.rasi"
  }
fi

# Copy default themes if they exist
if [[ -d "${LOOS_PATH}/default/rofi/themes" ]]; then
  echo "Copying rofi themes..."
  mkdir -p "$ROFI_DIR/themes"
  cp -rf "${LOOS_PATH}/default/rofi/themes/"* "$ROFI_DIR/themes/" 2>/dev/null || true
fi

# Set proper ownership
chown -R "$USER:$USER" "$ROFI_DIR" 2>/dev/null || true

# Verify installation
if command -v rofi &>/dev/null; then
  echo ""
  echo "Rofi version: $(rofi --version 2>&1 | head -1)"
  echo "Rofi launcher configured successfully!"
  echo ""
  echo "Launch with: SUPER+R"
  echo "Or run: rofi -show drun"
else
  echo ""
  echo "Warning: rofi command not found in PATH"
  echo "Rofi may need to be installed: sudo pacman -S rofi-wayland"
fi
