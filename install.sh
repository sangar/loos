#!/bin/bash
#
# loOS Installation Script
#
# For VM preparation (download packages without installing):
#   Run: ./prepare.sh
#
# This script will use cached packages from /var/cache/pacman/pkg/ if available

set -eEo pipefail

export LOOS_PATH="$HOME/.local/share/loos"
export LOOS_INSTALL="$LOOS_PATH/install"
export PATH="$LOOS_PATH/bin:$PATH"

# Check if packages are already cached (from prepare.sh)
if ls /var/cache/pacman/pkg/* 1>/dev/null 2>&1; then
  CACHED_PKGS=$(ls /var/cache/pacman/pkg/ | wc -l)
  if [[ $CACHED_PKGS -gt 10 ]]; then
    echo "=========================================="
    echo " Found $CACHED_PKGS cached packages!"
    echo " Installation will be faster using cache."
    echo "=========================================="
    echo ""
  fi
fi

# Keep sudo alive throughout the installation (refresh every 60 seconds)
if ! sudo -n true 2>/dev/null; then
  sudo -v
fi
while true; do sudo -n true; sleep 60; done &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null || true" EXIT

# helpers
source "$LOOS_INSTALL/preflight/all.sh"
source "$LOOS_INSTALL/packaging/all.sh"
source "$LOOS_INSTALL/config/all.sh"
source "$LOOS_INSTALL/login/all.sh"
source "$LOOS_INSTALL/post-install/all.sh"
