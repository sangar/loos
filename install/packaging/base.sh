# Install all base packages
mapfile -t packages < <(grep -v '^#' "$LOOS_INSTALL/loos-base.packages" | grep -v '^$')
loos-pkg-add "${packages[@]}"
