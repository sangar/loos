# Fix pacman sandbox issues on ARM kernel
if ! grep -q "DisableSandboxFilesystem" /etc/pacman.conf; then
  sudo sed -i 's/^DownloadUser = alpm$/DownloadUser = alpm\nDisableSandboxFilesystem\nDisableSandboxSyscalls/' /etc/pacman.conf
fi

# Remove stale locks
sudo rm -f /var/lib/pacman/db.lck

source "$LOOS_INSTALL/packaging/base.sh"
