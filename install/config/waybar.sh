set -u

WAYBAR_DIR="$HOME/.config/waybar"
mkdir -p "$WAYBAR_DIR"

# Copy waybar configs from loos if they don't exist or if loos has newer versions
if [ -d "$LOOS_PATH/config/waybar" ]; then
  cp -f "$LOOS_PATH/config/waybar/config" "$WAYBAR_DIR/config" 2>/dev/null || true
  cp -f "$LOOS_PATH/config/waybar/style.css" "$WAYBAR_DIR/style.css" 2>/dev/null || true
fi

# Validate config
echo "Validating waybar config..."
if ! python3 -c "import json; json.load(open('$WAYBAR_DIR/config'))" 2>/dev/null; then
  echo "Warning: waybar config is not valid JSON"
fi

# Create launcher script
cat >"$WAYBAR_DIR/launcher.sh" <<'EOF'
#!/bin/bash
walker -n -p dmenu
EOF

chmod +x "$WAYBAR_DIR/launcher.sh"
chown -R $USER:$USER "$WAYBAR_DIR"

# If waybar is not showing, user can run: loos-waybar-debug
