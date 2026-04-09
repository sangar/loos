#!/bin/bash
# Foot terminal configuration setup

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
FOOT_DIR="$USER_HOME/.config/foot"

echo "Setting up Foot terminal..."

# Ensure foot config directory exists
mkdir -p "$FOOT_DIR"

# Copy foot config from loos if it exists
if [[ -f "$LOOS_PATH/config/foot/foot.ini" ]]; then
  cp -f "$LOOS_PATH/config/foot/foot.ini" "$FOOT_DIR/foot.ini" 2>/dev/null || true
fi

# Set proper ownership
chown -R "$USER:$USER" "$FOOT_DIR" 2>/dev/null || true

echo "Foot terminal configured successfully!"
echo ""
echo "Config location: ~/.config/foot/foot.ini"
echo ""
echo "Usage:"
echo "  foot              - Start a new terminal window"
echo "  footclient        - Connect to foot server (fastest, requires 'foot --server')"
echo ""
echo "To enable server mode for faster terminal launches:"
echo "  foot --server &"
echo "  Or add to Hyprland autostart.conf: exec-once = foot --server"
echo ""
echo "If you get config errors, delete ~/.config/foot/foot.ini to use defaults"