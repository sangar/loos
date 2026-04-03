set -u

WAYBAR_DIR="$HOME/.config/waybar"
mkdir -p "$WAYBAR_DIR"

# Create launcher script (configs already copied by config.sh)
cat >"$WAYBAR_DIR/launcher.sh" <<'EOF'
#!/bin/bash
wofi --show=dmenu --width=400 --height=300
EOF

chmod +x "$WAYBAR_DIR/launcher.sh"
chown -R $USER:$USER "$WAYBAR_DIR"
