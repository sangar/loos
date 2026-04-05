# Copy over LoOS configs
mkdir -p ~/.config
cp -R ~/.local/share/loos/config/* ~/.config/

# Use default bashrc from LoOS
cp ~/.local/share/loos/default/bashrc ~/.bashrc

# Sync keyboard layout from vconsole to Hyprland
if command -v loos-keyboard-sync &>/dev/null; then
  loos-keyboard-sync
fi
