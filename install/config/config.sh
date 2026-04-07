# Copy over LoOS configs (modular structure)
mkdir -p ~/.config
cp -R ~/.local/share/loos/config/* ~/.config/

# Use default bashrc from LoOS
cp ~/.local/share/loos/default/bashrc ~/.bashrc

# Sync keyboard layout from vconsole to Hyprland
if command -v loos-keyboard-sync &>/dev/null; then
  loos-keyboard-sync
fi

# Refresh Hyprland defaults (system configs)
# User configs in ~/.config/hypr/user-*.conf are preserved
if command -v loos-refresh-hypr &>/dev/null; then
  loos-refresh-hypr
fi
