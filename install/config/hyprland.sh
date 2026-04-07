# Hyprland user configuration
# Sets up exec-once entries and user systemd services for portal, clipboard, polkit

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
