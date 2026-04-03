# Fix hyprpolkitagent service condition (it's too strict - prevents starting before WAYLAND_DISPLAY is set)
if [ -f /usr/lib/systemd/user/hyprpolkitagent.service ]; then
  sudo sed -i 's/^ConditionEnvironment=WAYLAND_DISPLAY/#ConditionEnvironment=WAYLAND_DISPLAY/' /usr/lib/systemd/user/hyprpolkitagent.service
fi

# Enable seatd service (required for DRM access - works with or without display manager)
sudo systemctl enable seatd.service 2>/dev/null || true
sudo systemctl start seatd.service 2>/dev/null || true

# Enable SDDM display manager
sudo systemctl enable sddm.service 2>/dev/null || true

# Add user to required groups for graphics access
sudo usermod -aG video "$USER" 2>/dev/null || true
sudo usermod -aG seat "$USER" 2>/dev/null || true

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)

# Create Hyprland config directory if needed
mkdir -p "$USER_HOME/.config/hypr"

# Hyprland config is copied by config.sh, add exec-once entries here
HYPRCONF="$USER_HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPRCONF" ]; then
  # Remove old entries if they exist with wrong paths
  sed -i '\|/usr/bin/xdg-desktop-portal|d' "$HYPRCONF"
  sed -i '\|/usr/bin/hyprpolkitagent|d' "$HYPRCONF"

  # Add exec-once commands after waybar if not already present
  if ! grep -q "xdg-desktop-portal-wlr" "$HYPRCONF"; then
    sed -i '/^exec-once = waybar &$/a\
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP\
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP\
exec-once = /usr/lib/xdg-desktop-portal-wlr\
exec-once = wl-clipboard history\
exec-once = /usr/lib/hyprpolkitagent/hyprpolkitagent' "$HYPRCONF"
  fi

  chown "$USER:$USER" "$HYPRCONF"
else
  echo "Warning: $HYPRCONF not found. Config should have been copied by config.sh."
fi

# Enable user services (optional - primarily for session restoration)
mkdir -p "$USER_HOME/.config/systemd/user"
systemctl --user enable xdg-desktop-portal.service 2>/dev/null || true
systemctl --user enable hyprpolkitagent.service 2>/dev/null || true

# Configure auto-start of Hyprland on TTY1 login (fallback when not using display manager)
# Note: When using SDDM, this is not needed but kept as fallback
BASH_PROFILE="$USER_HOME/.bash_profile"
if ! grep -q "exec start-hyprland" "$BASH_PROFILE" 2>/dev/null; then
  cat >>"$BASH_PROFILE" <<'EOF'

# Auto-start Hyprland on TTY1 (if not already in graphical session)
# This is a fallback for when SDDM is not running
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  # Ensure seatd is running (required for DRM access on ARM/embedded)
  if ! systemctl is-active --quiet seatd; then
    sudo systemctl start seatd
  fi
  exec start-hyprland
fi
EOF
  chown "$USER:$USER" "$BASH_PROFILE"
fi
