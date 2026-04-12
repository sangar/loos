# loOS Agent Guidelines

## Project Overview

loOS is a bash-based Arch Linux installation and configuration framework for setting up Hyprland desktop environments. It automates package installation, system configuration, and desktop environment setup on Arch-based systems (primarily ARM).

## Theming

Themes can be found in the `themes` folder. Each theme has a `backgrounds` folder and a
colors file named `colors.toml` which is used as the base colors for all configuration
files related to setting colors.

## Build/Lint/Test Commands

### Linting
```bash
# Lint all shell scripts
find . -type f -name "*.sh" -exec shellcheck {} \;

# Lint a specific file
shellcheck install.sh
shellcheck bin/loos-pkg-add
```

### Testing
```bash
# Test a specific component by sourcing in a subshell
bash -n install.sh                    # Syntax check only
bash -c 'source install.sh'           # Source test (dry run)

# Test individual utility scripts
bash bin/loos-pkg-missing hyprland    # Test package check
bash bin/loos-pkg-add fake-package    # Test package install (will fail safely)

# Full syntax validation for all scripts
find . -type f \( -name "*.sh" -o -name "loos-*" \) -exec bash -n {} \;
```

### Running a Single Test
```bash
# Syntax test single file
bash -n <file.sh>

# Functional test (in container/VM only - modifies system)
bash -x install/packaging/base.sh      # Trace execution
```

## Code Style Guidelines

### Shell Script Standards
- **Shebang**: Always use `#!/bin/bash` (not `#!/bin/sh`)
- **Error handling**: Use `set -eEo pipefail` in entry points
- **Strict mode**: Enable for all scripts that run standalone

### Formatting
- **Indentation**: 2 spaces (no tabs)
- **Line length**: Keep under 100 characters when possible
- **Blank lines**: One blank line between logical sections
- **Trailing**: No trailing whitespace; newline at end of file

### Naming Conventions
- **Variables**: UPPER_SNAKE_CASE for globals (e.g., `LOOS_PATH`, `USER_HOME`)
- **Local variables**: lower_snake_case (e.g., `tmp_dir`, `pkg`)
- **Functions**: lower_snake_case with descriptive names
- **Files**: `loos-*` prefix for executables in `bin/`, `*.sh` for shell scripts
- **Modules**: `all.sh` for aggregators, descriptive names for implementations

### Variable Usage
```bash
# Globals (export only when needed)
export LOOS_PATH="$HOME/.local/share/loos"
export LOOS_INSTALL="$LOOS_PATH/install"

# Always quote variables
loos-pkg-add "${packages[@]}"

# Check for empty/unset variables
if [[ -n ${VAR//[[:space:]]/} ]]; then
  # Variable is set and non-empty (ignoring whitespace)
fi
```

### Control Flow
```bash
# Use [[ ]] for conditionals
if [[ -n "$VAR" ]]; then
  # ...
fi

# Iterate properly over arrays
for pkg in "$@"; do
  # ...
done

# Exit codes: explicit 0/1 for boolean-style scripts
exit 0  # Success / true
exit 1  # Failure / false
```

### Error Handling
```bash
# Always check command outcomes with ||
sudo pacman -S --noconfirm --needed "$@" || exit 1

# Redirect stderr appropriately
curl -L -o file "$URL" 2>&1 | tail -3

# Use &>/dev/null for silent checks
if ! pacman -Q "$pkg" &>/dev/null; then
  # ...
fi

# Cleanup with trap (for temp files)
TMP_DIR=$(mktemp -d)
trap "rm -rf '$TMP_DIR'" EXIT
```

### Output & Logging
```bash
# Error messages to stderr in red
echo -e "\033[31mError: Package '$pkg' did not install\033[0m" >&2

# Warnings to stderr
echo "Warning: $HYPRCONF not found. Skipping..." >&2

# Info messages to stdout (no prefix needed for simple status)
echo "Installing LocalSend..."
```

### Comments
- Start files with brief purpose description
- Use inline comments sparingly - prefer self-documenting code
- Document workarounds and fixes (e.g., `# Fix pacman sandbox issues on ARM`)

### File Organization
```
bin/              # Executable utilities (loos-pkg-add, loos-pkg-missing)
install/          # Installation modules
  preflight/      # System preparation (all.sh, pacman.sh)
  packaging/      # Package management (all.sh, base.sh)
  config/         # Configurations (all.sh, git.sh, waybar.sh, lcsnd.sh)
  login/          # Login environment (all.sh, hypr.sh)
config/           # Static config files (waybar/)
```

### Module Pattern
```bash
# all.sh files aggregate their directory:
source "$LOOS_INSTALL/config/config.sh"
source "$LOOS_INSTALL/config/git.sh"

# Individual modules do one thing well
# - git.sh: Configure git user
# - waybar.sh: Setup waybar configuration
# - btop.sh: Setup btop system monitor with catppuccin theme
# - fastfetch.sh: Setup fastfetch with custom loOS config
# - lcsnd.sh: Install LocalSend
```

## Key Conventions

1. **Pacman integration**: Use `loos-pkg-add` and `loos-pkg-missing` wrappers
2. **User context**: Use `$USER` variable; get home via `getent passwd`
3. **Permissions**: Use `sudo` for system changes, `chown` for user files
4. **Temp files**: Always use `mktemp -d` and cleanup
5. **Sed patterns**: Use `|` as delimiter for paths to avoid escaping `/`
6. **Terminal**: `foot` is the default lightweight Wayland-native terminal (replaces alacritty for ARM/simple machines)
7. **System Monitor**: `btop` with catppuccin-mocha theme
8. **System Info**: `fastfetch` with custom loOS config
9. **Theme Manager**: `loos-theme` - 5 themes (persisted to `~/.config/loos/current-theme`)
10. **Wallpaper Manager**: `loos-wallpaper` - Rofi-based selector (persisted to `~/.config/loos/current-wallpaper`)
11. **Background Manager**: `loos-background` - Terminal backgrounds (persisted to `~/.config/loos/background.conf`)
12. **Auto-restore**: All theme/wallpaper/background settings restored on Hyprland login

## VM Preparation

For VM-based deployments, use the `prepare.sh` script to download all packages
without installing.

### Local Usage (from cloned repo)

```bash
# On base VM/image:
./prepare.sh    # Downloads packages to /var/cache/pacman/pkg/

# Clone the VM, then on clone:
./install.sh     # Uses cached packages (fast installation!)
```

### Remote Usage (via curl - no clone needed)

```bash
# On base VM/image - download packages without cloning:
curl -sSL https://raw.githubusercontent.com/sangar/loos/master/prepare.sh | bash

# Clone the VM, then on clone - clone repo and install:
git clone https://github.com/sangar/loos.git
cd loos
./install.sh     # Uses cached packages (fast installation!)
```

The `prepare.sh` script:
- Detects if run locally or remotely
- Downloads package list from GitHub when run via curl
- Uses `pacman -Sw` to download only, storing packages in `/var/cache/pacman/pkg/`
- For installation, the full repo must be cloned (install.sh sources many local files)

## AUR / Source Builds

Some packages are not in official Arch repositories and must be:
- Installed via AUR helper (optional `install/config/aur-helper.sh`)
- Built from source when AUR is unavailable

Source builds are preferred for ARM compatibility.

## Uninstall

To remove loOS from your system, use the `uninstall.sh` script:

```bash
./uninstall.sh
```

### Uninstall Modes

1. **Remove configs only** (SAFE) - Removes loOS configuration files but keeps all packages
2. **Full uninstall** (DANGEROUS) - Removes configs AND tries to remove packages
3. **Destructive** (DESTRUCTIVE) - Full cleanup including user data (nvim, mise, etc.)

### What Gets Removed

- loOS binaries (`~/.local/bin/loos-*`)
- loOS installation (`~/.local/share/loos`)
- loOS config state (`~/.config/loos`)
- Application configs (hypr, waybar, rofi, foot, btop, etc.)
- Systemd user units (xdg-desktop-portal, hyprpolkitagent)
- Wallpapers and cache (`~/.local/share/loos`, `~/.cache/loos`)
- .bashrc entries (loOS-specific lines)

### What Stays (by default)

- Installed packages (unless full uninstall mode)
- User files in home directory
- Git repositories and projects

## Testing Notes

- No automated test suite currently exists
- Test manually in Arch Linux VM/container
- Syntax checking with `bash -n` is the primary validation
- Shellcheck recommended for style enforcement
- Be careful: scripts modify system state (pacman, system configs)
