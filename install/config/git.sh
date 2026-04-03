set -u

# Set git user identification
# Use env vars if provided, otherwise prompt user
if [[ -n ${LOOS_USER_NAME:-} ]]; then
  git config --global user.name "$LOOS_USER_NAME"
else
  # Check if git name is already configured
  if ! git config --global user.name &>/dev/null; then
    echo "Git user name not configured."
    read -p "Enter your git user name (or press Enter to skip): " git_name
    if [[ -n "$git_name" ]]; then
      git config --global user.name "$git_name"
    fi
  fi
fi

if [[ -n ${LOOS_USER_EMAIL:-} ]]; then
  git config --global user.email "$LOOS_USER_EMAIL"
else
  # Check if git email is already configured
  if ! git config --global user.email &>/dev/null; then
    echo "Git user email not configured."
    read -p "Enter your git user email (or press Enter to skip): " git_email
    if [[ -n "$git_email" ]]; then
      git config --global user.email "$git_email"
    fi
  fi
fi
