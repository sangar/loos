#!/bin/bash

# print ascii logo
cat <<'EOF'
 _            ____   _____
| |          / __ \ / ____|
| |      ___| |  | | (___
| |     / _ \ |  | |\___ \
| |____|  L | |__| |  __) |
|______|\___/\____/|_____/

EOF

sudo pacman -Syu --noconfirm --needed --disable-sandbox-filesystem --disable-sandbox-syscalls git

echo -e "\nCloning loOS from https://github.com/sangar/loos.git"
rm -fr ~/.local/share/loos/
git clone "https://github.com/sangar/loos.git" ~/.local/share/loos >/dev/null

echo -e "\nInstallation starting..."
source ~/.local/share/loos/install.sh
