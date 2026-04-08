# Activate mise for current shell
if command -v mise &> /dev/null; then
  eval "$(mise activate bash)"
fi

# Install global tools via mise
mise use -g node@latest
mise use -g rust@latest
