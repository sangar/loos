set -u

echo "Installing LocalSend..."

USER_HOME=$(getent passwd "$USER" | cut -d: -f6)

LOCALEND_VERSION=$(curl -sL "https://api.github.com/repos/localsend/localsend/releases/latest" | grep -oP '"tag_name":\s*"\K[^"]+' | head -1)
DEB_URL="https://github.com/localsend/localsend/releases/download/${LOCALEND_VERSION}/LocalSend-${LOCALEND_VERSION#v}-linux-arm-64.deb"

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

curl -L -o localsend.deb "$DEB_URL" 2>&1 | tail -3

ar -x localsend.deb
tar -xf data.tar.*

mkdir -p "$USER_HOME/.local/share/localsend"
cp -r usr/share/localsend_app "$USER_HOME/.local/share/localsend/"
mkdir -p "$USER_HOME/.local/bin"
ln -sf "$USER_HOME/.local/share/localsend/localsend_app" "$USER_HOME/.local/bin/localsend"

mkdir -p "$USER_HOME/.local/share/applications"
cat >"$USER_HOME/.local/share/applications/localsend.desktop" <<EOF
[Desktop Entry]
Name=LocalSend
Comment=Share files to nearby devices
Exec=$USER_HOME/.local/share/localsend/localsend_app
Icon=localsend_app
Terminal=false
Type=Application
Categories=Network;
EOF

chown -R "$USER:$USER" "$USER_HOME/.local/"

rm -rf "$TMP_DIR"

if ! pacman -Q libayatana-appindicator &>/dev/null; then
  echo "Installing missing dependency..."
  sudo pacman -S --noconfirm libayatana-appindicator
fi
