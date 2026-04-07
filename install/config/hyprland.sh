# Hyprland configuration setup
# Adds portal/polkit/clipboard to autostart and configures Pi 5 environment

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
LOOS_DEFAULT="$USER_HOME/.local/share/loos/default/hypr"

# Ensure Hyprland config directory exists
mkdir -p "$USER_HOME/.config/hypr"
mkdir -p "$USER_HOME/.config/environment.d"

# Update autostart.conf with portal/polkit/clipboard (modular approach)
# This modifies the system default, which will be reloaded on next login
AUTOSTART_CONF="$LOOS_DEFAULT/autostart.conf"
if [ -f "$AUTOSTART_CONF" ]; then
  # Remove old entries if they exist with wrong paths
  sed -i '\|/usr/bin/xdg-desktop-portal|d' "$AUTOSTART_CONF"
  sed -i '\|/usr/bin/hyprpolkitagent|d' "$AUTOSTART_CONF"

  # Add exec-once commands after waybar if not already present
  if ! grep -q "xdg-desktop-portal-wlr" "$AUTOSTART_CONF"; then
    sed -i '/^exec-once = waybar.*$/a\
# Portal, polkit, clipboard - added by install/config/hyprland.sh\
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP\
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP\
exec-once = /usr/lib/xdg-desktop-portal-wlr\
exec-once = wl-clipboard history\
exec-once = /usr/lib/hyprpolkitagent/hyprpolkitagent' "$AUTOSTART_CONF"
  fi

  chown "$USER:$USER" "$AUTOSTART_CONF"
else
  echo "Warning: $AUTOSTART_CONF not found. Refresh may be needed."
fi

# Link Pi 5 environment variables to environment.d (systemd will load these)
PI5_ENV="$LOOS_DEFAULT/pi5-environment.conf"
if [ -f "$PI5_ENV" ] && [ ! -f "$USER_HOME/.config/environment.d/99-pi5.conf" ]; then
  ln -sf "$PI5_ENV" "$USER_HOME/.config/environment.d/99-pi5.conf"
fi

# Enable user services
mkdir -p "$USER_HOME/.config/systemd/user"
systemctl --user enable xdg-desktop-portal.service 2>/dev/null || true
systemctl --user enable hyprpolkitagent.service 2>/dev/null || true
