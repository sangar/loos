set -u

# Set identification from install inputs (variables are optional)
if [[ -n ${LOOS_USER_NAME:-} ]]; then
  git config --global user.name "$LOOS_USER_NAME"
fi

if [[ -n ${LOOS_USER_EMAIL:-} ]]; then
  git config --global user.email "$LOOS_USER_EMAIL"
fi
