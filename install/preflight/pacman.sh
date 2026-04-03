# Fix pacman sandbox issues on ARM kernel
# Check if DisableSandbox exists (commented or not) but not DisableSandboxFilesystem/Syscalls
if ! grep -q "^#\?DisableSandbox$" /etc/pacman.conf; then
  sudo sed -i 's/^DownloadUser = alpm$/DownloadUser = alpm\nDisableSandbox/' /etc/pacman.conf
fi
