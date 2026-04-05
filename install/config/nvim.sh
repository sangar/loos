# Install LazyVim configuration for Neovim

NVIM_CONFIG_DIR="${HOME}/.config/nvim"
NVIM_DATA_DIR="${HOME}/.local/share/nvim"
NVIM_STATE_DIR="${HOME}/.local/state/nvim"

echo "Setting up LazyVim for Neovim..."

# Check if nvim is installed
if ! command -v nvim &>/dev/null; then
  echo "Warning: Neovim (nvim) is not installed. Skipping LazyVim setup." >&2
  exit 0
fi

# Backup existing Neovim configuration if present
if [[ -d "$NVIM_CONFIG_DIR" ]] && [[ ! -L "$NVIM_CONFIG_DIR" ]]; then
  BACKUP_DIR="${HOME}/.config/nvim.bak.$(date +%Y%m%d%H%M%S)"
  echo "Backing up existing Neovim config to ${BACKUP_DIR}..."
  mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
fi

# Also backup old data/state directories
for dir in "$NVIM_DATA_DIR" "$NVIM_STATE_DIR"; do
  if [[ -d "$dir" ]]; then
    BACKUP_DIR="${dir}.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backing up ${dir} to ${BACKUP_DIR}..."
    mv "$dir" "$BACKUP_DIR"
  fi
done

# Clone LazyVim starter template
echo "Cloning LazyVim starter configuration..."
if [[ -d "$NVIM_CONFIG_DIR" ]]; then
  rm -rf "$NVIM_CONFIG_DIR"
fi
git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"

# Remove the .git directory from the starter to make it your own
rm -rf "${NVIM_CONFIG_DIR}/.git"

echo "LazyVim configuration installed successfully!"
echo "Start nvim to let LazyVim bootstrap itself (this may take a minute on first run)."
echo ""
echo "Note: On first launch, press 'q' to close the startup screen, then run ':checkhealth'"
echo "      to verify everything is working correctly."
