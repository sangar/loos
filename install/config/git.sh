set -u

# Set git user identification from environment variables if provided
# Silently skip if not set - user can configure manually later

if [[ -n ${LOOS_USER_NAME:-} ]]; then
  git config --global user.name "$LOOS_USER_NAME"
fi

if [[ -n ${LOOS_USER_EMAIL:-} ]]; then
  git config --global user.email "$LOOS_USER_EMAIL"
fi
