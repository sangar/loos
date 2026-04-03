set -u

WAYBAR_DIR="$HOME/.config/waybar"
mkdir -p "$WAYBAR_DIR"

cat "$LOOS_PATH/config/waybar/config" >"$WAYBAR_DIR/config"
cat "$LOOS_PATH/config/waybar/style.css" >"$WAYBAR_DIR/style.css"

cat >"$WAYBAR_DIR/launcher.sh" <<'EOF'
#!/bin/bash
wofi --show=dmenu --width=400 --height=300
EOF

chmod +x "$WAYBAR_DIR/launcher.sh"
chown -R $USER:$USER "$WAYBAR_DIR"

HYPRCONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPRCONF" ]; then
  if ! grep -q "wofi" "$HYPRCONF"; then
    sed -i 's/exec-once = waybar &/exec-once = waybar \&\nexec-once = wofi/' "$HYPRCONF"
    chown $USER:$USER "$HYPRCONF"
  fi
fi
