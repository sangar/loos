#!/bin/bash
# Waybar configuration setup

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
WAYBAR_DIR="$USER_HOME/.config/waybar"

echo "Setting up Waybar..."

# Create waybar config directory
mkdir -p "$WAYBAR_DIR"

# Copy base waybar config from loos
if [ -d "$LOOS_PATH/config/waybar" ]; then
  # Copy main config
  cp -f "$LOOS_PATH/config/waybar/config" "$WAYBAR_DIR/config" 2>/dev/null || true

  # Copy default style (will be overridden by theme switcher)
  cp -f "$LOOS_PATH/config/waybar/style.css" "$WAYBAR_DIR/style.css" 2>/dev/null || true
fi

# Validate config
echo "Validating waybar config..."
if ! python3 -c "import json; json.load(open('$WAYBAR_DIR/config'))" 2>/dev/null; then
  echo "Warning: waybar config is not valid JSON"
fi

# Create launcher script using rofi
cat >"$WAYBAR_DIR/launcher.sh" <<'EOF'
#!/bin/bash
# Rofi application launcher
rofi -show drun
EOF

chmod +x "$WAYBAR_DIR/launcher.sh"
chown -R "$USER:$USER" "$WAYBAR_DIR"

echo "Waybar configured successfully!"
echo ""
echo "Modules enabled:"
echo "  Left:  Workspaces, Window title"
echo "  Center: Clock"
echo "  Right: Audio, Network, Battery, System tray"
echo ""
echo "If waybar is not showing, run: loos-waybar-debug"
