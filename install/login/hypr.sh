# Fix hyprpolkitagent service condition (it's too strict - prevents starting before WAYLAND_DISPLAY is set)
if [ -f /usr/lib/systemd/user/hyprpolkitagent.service ]; then
  sudo sed -i 's/^ConditionEnvironment=WAYLAND_DISPLAY/#ConditionEnvironment=WAYLAND_DISPLAY/' /usr/lib/systemd/user/hyprpolkitagent.service
fi

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)

# Create Hyprland config directory if needed
mkdir -p "$USER_HOME/.config/hypr"

# Hyprland config is copied by config.sh, add exec-once entries here
HYPRCONF="$USER_HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPRCONF" ]; then
  # Remove old entries if they exist with wrong paths
  sudo sed -i '\|/usr/bin/xdg-desktop-portal|d' "$HYPRCONF"
  sudo sed -i '\|/usr/bin/hyprpolkitagent|d' "$HYPRCONF"

  # Add exec-once commands after waybar if not already present
  if ! grep -q "/usr/lib/xdg-desktop-portal" "$HYPRCONF"; then
    sudo sed -i 's/exec-once = waybar &/exec-once = waybar \&\nexec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP\nexec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP\nexec-once = \/usr\/lib\/xdg-desktop-portal -r\nexec-once = wl-clipboard history\nexec-once = \/usr\/lib\/hyprpolkitagent\/hyprpolkitagent/' "$HYPRCONF"
  fi

  chown "$USER:$USER" "$HYPRCONF"
else
  echo "Warning: $HYPRCONF not found. Config should have been copied by config.sh."
fi

# Enable user services (optional - primarily for session restoration)
mkdir -p "$USER_HOME/.config/systemd/user"
systemctl --user enable --now xdg-desktop-portal.service 2>/dev/null || true
systemctl --user enable --now hyprpolkitagent.service 2>/dev/null || true
