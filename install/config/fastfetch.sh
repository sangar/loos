#!/bin/bash
# Fastfetch configuration setup

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
FASTFETCH_DIR="$USER_HOME/.config/fastfetch"

echo "Setting up Fastfetch..."

# Ensure fastfetch config directory exists
mkdir -p "$FASTFETCH_DIR"

# Copy fastfetch config from loos
if [[ -f "$LOOS_PATH/config/fastfetch/config.jsonc" ]]; then
  cp -f "$LOOS_PATH/config/fastfetch/config.jsonc" "$FASTFETCH_DIR/config.jsonc" 2>/dev/null || true
fi

# Set proper ownership
chown -R "$USER:$USER" "$FASTFETCH_DIR" 2>/dev/null || true

echo "Fastfetch configured successfully!"
echo ""
echo "Add to your ~/.bashrc to show on terminal start:"
echo "  fastfetch"
echo ""
echo "Or run 'fastfetch' manually"
