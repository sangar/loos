# Copy over LoOS configs
mkdir -p ~/.config
cp -R ~/.local/share/loos/config/* ~/.config/

# Use default bashrc from LoOS
cp ~/.local/share/loos/default/bashrc ~/.bashrc
