#!/bin/bash

set -eEo pipefail

export LOOS_PATH="$HOME/.local/share/loos"
export LOOS_INSTALL="$LOOS_PATH/install"
export PATH="$LOOS_PATH/bin:$PATH"

# helpers
source "$LOOS_INSTALL/preflight/all.sh"
source "$LOOS_INSTALL/packaging/all.sh"
source "$LOOS_INSTALL/config/all.sh"
source "$LOOS_INSTALL/login/all.sh"
source "$LOOS_INSTALL/post-install/all.sh"
