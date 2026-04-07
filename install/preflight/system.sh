# System-level prerequisites for Hyprland on ARM/Raspberry Pi 5
# These must be configured before the display manager and graphical session start

# Fix hyprpolkitagent service condition (too strict - prevents starting before WAYLAND_DISPLAY is set)
if [ -f /usr/lib/systemd/user/hyprpolkitagent.service ]; then
  sudo sed -i 's/^ConditionEnvironment=WAYLAND_DISPLAY/#ConditionEnvironment=WAYLAND_DISPLAY/' /usr/lib/systemd/user/hyprpolkitagent.service
fi

# Enable seatd service (required for DRM access - works with or without display manager)
# Critical for ARM/embedded systems like Raspberry Pi 5
sudo systemctl enable seatd.service 2>/dev/null || true
sudo systemctl start seatd.service 2>/dev/null || true

# Add user to required groups for graphics access
sudo usermod -aG video "$USER" 2>/dev/null || true
sudo usermod -aG seat "$USER" 2>/dev/null || true
