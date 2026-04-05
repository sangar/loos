#!/bin/bash

set -eEo pipefail

export LOOS_PATH="$HOME/.local/share/loos"
export LOOS_INSTALL="$LOOS_PATH/install"
export PATH="$LOOS_PATH/bin:$PATH"

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
