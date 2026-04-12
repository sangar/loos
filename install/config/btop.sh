#!/bin/bash
# Btop configuration setup

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
BTOP_DIR="$USER_HOME/.config/btop"

echo "Setting up Btop..."

# Ensure btop config directory exists
mkdir -p "$BTOP_DIR/themes"

# Copy btop config from loos
if [[ -f "$LOOS_PATH/config/btop/btop.conf" ]]; then
  cp -f "$LOOS_PATH/config/btop/btop.conf" "$BTOP_DIR/btop.conf" 2>/dev/null || true
fi

# Set proper ownership
chown -R "$USER:$USER" "$BTOP_DIR" 2>/dev/null || true

echo "Btop configured successfully!"
echo ""
echo "Run 'btop' to launch system monitor"
echo "Press '?' in btop for help"
