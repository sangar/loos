#!/bin/bash
# Walker launcher configuration setup
# Builds walker from source for Arch/Manjaro ARM since it's only in AUR

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
LOOS_DEFAULT="$USER_HOME/.local/share/loos/default"
WALKER_DIR="$USER_HOME/.config/walker"
WALKER_BIN="$USER_HOME/.local/bin/walker"

echo "Setting up Walker launcher..."

# Function to build elephant (walker dependency) from source
build_elephant() {
  echo "Building elephant from source (walker dependency)..."

  local BUILD_DIR=$(mktemp -d)
  trap "rm -rf '$BUILD_DIR'" EXIT

  cd "$BUILD_DIR"

  echo "Cloning elephant source..."
  if ! git clone --depth 1 https://github.com/abenz1267/elephant.git; then
    echo "Error: Failed to clone elephant repository" >&2
    return 1
  fi

  cd elephant

  if ! command -v cargo &>/dev/null; then
    echo "Error: Rust/Cargo not found" >&2
    return 1
  fi

  echo "Building elephant..."
  if ! cargo build --release; then
    echo "Error: Failed to build elephant" >&2
    return 1
  fi

  mkdir -p "$USER_HOME/.local/bin"
  cp "target/release/elephant" "$USER_HOME/.local/bin/elephant"
  chmod +x "$USER_HOME/.local/bin/elephant"

  echo "Elephant built successfully!"
}

# Function to build walker from source
build_walker() {
  echo "Building walker from source (required for ARM/AUR packages)..."

  # First ensure elephant is available (walker dependency)
  if ! command -v elephant &>/dev/null && [[ ! -x "$USER_HOME/.local/bin/elephant" ]]; then
    echo "Elephant not found, building it first..."
    if command -v yay &>/dev/null; then
      yay -S --noconfirm elephant || build_elephant
    elif command -v paru &>/dev/null; then
      paru -S --noconfirm elephant || build_elephant
    else
      build_elephant
    fi
  fi

  # Create temporary build directory
  local BUILD_DIR=$(mktemp -d)
  trap "rm -rf '$BUILD_DIR'" EXIT

  cd "$BUILD_DIR"

  # Clone walker repository
  echo "Cloning walker source..."
  if ! git clone --depth 1 https://github.com/abenz1267/walker.git; then
    echo "Error: Failed to clone walker repository" >&2
    return 1
  fi

  cd walker

  # Check if cargo is available
  if ! command -v cargo &>/dev/null; then
    echo "Error: Rust/Cargo not found. Installing rust..." >&2
    loos-pkg-add rust
  fi

  # Install build dependencies
  echo "Installing build dependencies..."
  loos-pkg-add gtk4 gtk4-layer-shell poppler-glib cairo protobuf

  # Build walker
  echo "Building walker (this may take a few minutes)..."
  if ! cargo build --release; then
    echo "Error: Failed to build walker" >&2
    return 1
  fi

  # Install to user's local bin
  mkdir -p "$USER_HOME/.local/bin"
  cp "target/release/walker" "$WALKER_BIN"
  chmod +x "$WALKER_BIN"

  echo "Walker built successfully!"
}

# Check if walker is already installed
if ! command -v walker &>/dev/null; then
  # Check if we have a local build
  if [[ -x "$WALKER_BIN" ]]; then
    echo "Using existing walker build at $WALKER_BIN"
  else
    # Try to install via AUR helper if available
    if command -v yay &>/dev/null; then
      echo "Installing walker via yay (AUR)..."
      yay -S --noconfirm walker || build_walker
    elif command -v paru &>/dev/null; then
      echo "Installing walker via paru (AUR)..."
      paru -S --noconfirm walker || build_walker
    else
      # No AUR helper, build from source
      build_walker
    fi
  fi
else
  echo "Walker already installed: $(which walker)"
fi

# Ensure walker is in PATH via .bashrc if using local build
if [[ -x "$WALKER_BIN" ]] && ! grep -q "\.local/bin" "$USER_HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"
fi

# Ensure walker config directory exists
mkdir -p "$WALKER_DIR"
mkdir -p "$WALKER_DIR/themes"

# Copy walker configs from loos if they don't exist or if loos has newer versions
if [[ -f "$LOOS_PATH/config/walker/config.toml" ]]; then
  cp -f "$LOOS_PATH/config/walker/config.toml" "$WALKER_DIR/config.toml" 2>/dev/null || true
fi

# Copy default themes
if [[ -d "$LOOS_DEFAULT/walker/themes" ]]; then
  cp -rf "$LOOS_DEFAULT/walker/themes/"* "$WALKER_DIR/themes/" 2>/dev/null || true
fi

# Set proper ownership
chown -R "$USER:$USER" "$WALKER_DIR" 2>/dev/null || true

# Create walker restart script
cat > "$USER_HOME/.local/bin/loos-restart-walker" <<'EOF'
#!/bin/bash
# Restart walker service

# Kill existing walker
killall walker 2>/dev/null || true

# Wait for process to die
sleep 0.5

# Start service
if [[ -x "$HOME/.local/bin/walker" ]]; then
  "$HOME/.local/bin/walker" --gapplication-service > /tmp/walker.log 2>&1 &
else
  walker --gapplication-service > /tmp/walker.log 2>&1 &
fi
EOF

chmod +x "$USER_HOME/.local/bin/loos-restart-walker" 2>/dev/null || true
chown "$USER:$USER" "$USER_HOME/.local/bin/loos-restart-walker" 2>/dev/null || true

# Create systemd user service for walker (optional, for better service management)
SERVICE_DIR="$USER_HOME/.config/systemd/user"
mkdir -p "$SERVICE_DIR"

# Detect walker binary path for service file
WALKER_PATH=$(command -v walker 2>/dev/null || echo "$WALKER_BIN")
if [[ ! -x "$WALKER_PATH" ]]; then
  WALKER_PATH="$WALKER_BIN"
fi

cat > "$SERVICE_DIR/walker.service" <<EOF
[Unit]
Description=Walker Application Launcher Service
After=graphical-session.target

[Service]
Type=simple
ExecStart=$WALKER_PATH --gapplication-service
Restart=on-failure
RestartSec=1

[Install]
WantedBy=default.target
EOF

chown "$USER:$USER" "$SERVICE_DIR/walker.service" 2>/dev/null || true

# Reload systemd user daemon
systemctl --user daemon-reload 2>/dev/null || true

# Enable the service (don't start it yet, Hyprland autostart handles that)
systemctl --user enable walker.service 2>/dev/null || true

echo "Walker launcher configured successfully!"
echo "Note: walker will start automatically with Hyprland via autostart.conf"
echo ""
echo "To restart walker manually, run: loos-restart-walker"
