#!/bin/bash
# Walker launcher configuration setup
# Replaces wofi with walker as the default application launcher

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
LOOS_DEFAULT="$USER_HOME/.local/share/loos/default"
WALKER_DIR="$USER_HOME/.config/walker"

# Ensure walker config directory exists
mkdir -p "$WALKER_DIR"
mkdir -p "$WALKER_DIR/themes"

# Copy walker configs from loos if they don't exist or if loos has newer versions
if [ -d "$LOOS_PATH/config/walker" ]; then
  cp -f "$LOOS_PATH/config/walker/config.toml" "$WALKER_DIR/config.toml" 2>/dev/null || true
fi

# Copy default themes
if [ -d "$LOOS_DEFAULT/walker/themes" ]; then
  cp -rf "$LOOS_DEFAULT/walker/themes/"* "$WALKER_DIR/themes/" 2>/dev/null || true
fi

# Set proper ownership
chown -R "$USER:$USER" "$WALKER_DIR"

# Create walker restart script
cat >"$USER_HOME/.local/bin/loos-restart-walker" <<'EOF'
#!/bin/bash
# Restart walker service
killall walker 2>/dev/null || true
sleep 0.5
walker --gapplication-service > /tmp/walker.log 2>&1 &
EOF

chmod +x "$USER_HOME/.local/bin/loos-restart-walker" 2>/dev/null || true

# Create systemd user service for walker (optional, for better service management)
SERVICE_DIR="$USER_HOME/.config/systemd/user"
mkdir -p "$SERVICE_DIR"

cat >"$SERVICE_DIR/walker.service" <<EOF
[Unit]
Description=Walker Application Launcher Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/walker --gapplication-service
Restart=on-failure
RestartSec=1

[Install]
WantedBy=default.target
EOF

# Reload systemd user daemon
systemctl --user daemon-reload 2>/dev/null || true

# Enable the service (don't start it yet, Hyprland autostart handles that)
systemctl --user enable walker.service 2>/dev/null || true

echo "Walker launcher configured successfully"
echo "Note: walker will start automatically with Hyprland via autostart.conf"
