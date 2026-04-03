# Fix pacman sandbox issues on ARM kernel
if ! grep -q "^DisableSandbox$" /etc/pacman.conf; then
  sudo sed -i 's/^DownloadUser = alpm$/DownloadUser = alpm\nDisableSandbox/' /etc/pacman.conf
fi
