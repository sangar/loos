# loOS Agent Guide

loOS is a Hyprland-based desktop environment configuration system for Arch Linux, with Raspberry Pi 5 optimizations.

## Architecture

**Three-layer config system:**
- `install/` - Installation scripts that set up configs on target systems
- `config/` - Template configs copied to `~/.config/` during install
- `default/` - System defaults installed to `~/.local/share/loos/default/`
- `themes/` - 20 color themes with app-specific configs
- `bin/` - Utility commands (added to PATH during install)

## Key Commands

**Installation:**
```bash
# Quick install (downloads from GitHub)
curl -sSL https://raw.githubusercontent.com/sangar/loos/master/boot.sh | bash

# Local install (from repo)
./install.sh

# VM preparation (download packages without installing)
./prepare.sh
```

**Development:**
```bash
# Refresh Hyprland configs from repo to user dir
./bin/loos-refresh-hypr

# Sync keyboard layout from vconsole to Hyprland
./bin/loos-keyboard-sync

# Check missing packages
./bin/loos-pkg-missing <package>

# Add packages (with cache check)
./bin/loos-pkg-add <package>
```

## Config Management Pattern

**System vs User configs:**
- System defaults live in `~/.local/share/loos/default/hypr/` (from `default/hypr/`)
- User overrides go in `~/.config/hypr/user-*.conf` files
- `hyprland.conf` sources system first, then user configs (user wins)

**When editing configs:**
- Edit `default/hypr/` files for system-wide defaults
- Template user overrides go in `config/hypr/user-*.conf`
- Never edit `~/.config/hypr/` directly (those are user customizations)

## Theme System

**Theme structure:** `themes/<name>/`
- `colors.toml` - 16-color palette + accent/foreground/background
- `vscode.json` - VS Code color overrides
- `neovim.lua` - Neovim colorscheme reference
- `waybar.css` - Waybar color variables
- `btop.theme` - Btop color theme
- `hyprland.conf` - Hyprland-specific colors
- `backgrounds/` - Wallpaper images
- `light.mode` - Marker file for light themes

**Applying themes:** Themes are applied by scripts that:
1. Read `colors.toml`
2. Generate app-specific configs (waybar CSS, btop theme, etc.)
3. Copy to `~/.config/`
4. Reload running apps

## Testing Changes

**To test config changes locally:**
```bash
# Edit default/hypr/ files, then:
./bin/loos-refresh-hypr
# Refresh Hyprland: SUPER+Q (quit) and re-login, or restart Hyprland
```

**To test install scripts:**
```bash
# Run specific config module
LOOS_PATH="$PWD" LOOS_INSTALL="$PWD/install" bash install/config/waybar.sh
```

## Key Files

| Purpose | Location |
|---------|----------|
| Package list | `install/loos-base.packages` |
| Main install | `install.sh` |
| Hyprland entry | `config/hypr/hyprland.conf` |
| System defaults | `default/hypr/*.conf` |
| User templates | `config/hypr/user-*.conf` |
| Install modules | `install/config/*.sh` |

## Pi 5 Specifics

- `default/hypr/pi5-performance.conf` - GPU/performance tweaks
- `default/hyhr/pi5-environment.conf` - Environment variables for Pi 5
- `pi5-environment.conf` is linked to `~/.config/environment.d/99-pi5.conf`

## Uninstall

```bash
./uninstall.sh
```
Modes: configs-only, full (configs+packages), destructive (+user data)

## Dependencies

Core: hyprland, foot, waybar, rofi-wayland, uwsm, sddm, dunst, btop, fastfetch, mise

See `FEATURES.md` for full feature checklist and omarchy comparison.
