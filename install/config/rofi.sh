#!/bin/bash
# Rofi-wayland launcher configuration setup

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
LOOS_DEFAULT="$USER_HOME/.local/share/loos/default"
ROFI_DIR="$USER_HOME/.config/rofi"

echo "Setting up Rofi launcher..."

# Ensure rofi config directory exists
mkdir -p "$ROFI_DIR"

# Copy rofi configs from loos if they don't exist or if loos has newer versions
if [[ -f "$LOOS_PATH/config/rofi/config.rasi" ]]; then
  cp -f "$LOOS_PATH/config/rofi/config.rasi" "$ROFI_DIR/config.rasi" 2>/dev/null || true
fi

# Copy default themes
if [[ -d "$LOOS_DEFAULT/rofi/themes" ]]; then
  mkdir -p "$ROFI_DIR/themes"
  cp -rf "$LOOS_DEFAULT/rofi/themes/"* "$ROFI_DIR/themes/" 2>/dev/null || true
fi

# Set proper ownership
chown -R "$USER:$USER" "$ROFI_DIR" 2>/dev/null || true

echo "Rofi launcher configured successfully!"
echo ""
echo "Press SUPER+R to launch rofi"
