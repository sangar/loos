#!/bin/bash
# Theme and wallpaper configuration setup

set -u

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
LOOS_DEFAULT="$USER_HOME/.local/share/loos/default"
WALLPAPER_DIR="$USER_HOME/.local/share/loos/wallpapers"
THEME_DIR="$USER_HOME/.local/share/loos/themes"
LOOS_CONFIG="$USER_HOME/.config/loos"

echo "Setting up themes and wallpapers..."

# Create directories
mkdir -p "$WALLPAPER_DIR"
mkdir -p "$THEME_DIR"
mkdir -p "$LOOS_CONFIG"

# Copy default wallpapers if they exist in loos
if [[ -d "$LOOS_PATH/default/wallpapers" ]]; then
  echo "Copying default wallpapers..."
  cp -r "$LOOS_PATH/default/wallpapers/"* "$WALLPAPER_DIR/" 2>/dev/null || true
fi

# Copy theme files
if [[ -d "$LOOS_PATH/config/themes" ]]; then
  echo "Copying theme definitions..."
  mkdir -p "$USER_HOME/.local/share/loos/config/themes"
  cp -r "$LOOS_PATH/config/themes/"* "$USER_HOME/.local/share/loos/config/themes/" 2>/dev/null || true
fi

# Copy app theme templates
for app in foot rofi waybar; do
  if [[ -d "$LOOS_PATH/config/$app/themes" ]]; then
    echo "Copying $app theme templates..."
    mkdir -p "$USER_HOME/.local/share/loos/config/$app/themes"
    cp -r "$LOOS_PATH/config/$app/themes/"* "$USER_HOME/.local/share/loos/config/$app/themes/" 2>/dev/null || true
  fi
done

# Set initial wallpaper on first install
if [[ ! -f "$LOOS_CONFIG/current-wallpaper" ]]; then
  echo "No current wallpaper set, will set random on first launch"
fi

# Set initial theme on first install
if [[ ! -f "$LOOS_CONFIG/current-theme" ]]; then
  echo "Setting default theme..."
  echo "catppuccin-mocha" > "$LOOS_CONFIG/current-theme"
fi

# Initialize background config
if [[ ! -f "$LOOS_CONFIG/background.conf" ]]; then
  echo "Initializing background settings..."
  cat > "$LOOS_CONFIG/background.conf" << 'EOF'
# loOS Background Configuration
BACKGROUND_MODE="solid"
BACKGROUND_OPACITY="0.8"
BACKGROUND_COLOR=""
EOF
fi

# Set proper ownership
chown -R "$USER:$USER" "$WALLPAPER_DIR" 2>/dev/null || true
chown -R "$USER:$USER" "$THEME_DIR" 2>/dev/null || true
chown -R "$USER:$USER" "$LOOS_CONFIG" 2>/dev/null || true
chown -R "$USER:$USER" "$USER_HOME/.local/share/loos/config" 2>/dev/null || true

echo "Theme and wallpaper setup complete!"
echo ""
echo "Usage:"
echo "  loos-wallpaper select    - Select wallpaper via rofi"
echo "  loos-wallpaper random    - Set random wallpaper"
echo "  loos-wallpaper list      - List available wallpapers"
echo ""
echo "  loos-theme select        - Select theme via rofi"
echo "  loos-theme list          - List available themes"
echo "  loos-theme apply <name>  - Apply specific theme"
echo "  loos-theme info <name>   - Show theme details"
echo ""
echo "  loos-background solid    - Solid background"
echo "  loos-background transparent [0.x] - Transparent terminal"
echo "  loos-background preset <solid|transparent|glass> - Quick preset"
echo "  loos-background show     - Show current settings"
echo ""
echo "Theme files: ~/.local/share/loos/config/{app}/themes/"
echo "Wallpaper dir: $WALLPAPER_DIR"
