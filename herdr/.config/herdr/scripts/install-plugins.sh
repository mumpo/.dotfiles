#!/usr/bin/env sh
set -eu

# Install Herdr plugins from GitHub.
# Herdr expects GitHub shorthand: owner/repo[/subdir...]
# Re-running this script is OK; GitHub-managed plugins are replaced/updated.

command -v herdr >/dev/null 2>&1 || {
  echo "error: herdr is not installed or not on PATH" >&2
  exit 1
}

install_plugin() {
  repo="$1"

  echo "Installing Herdr plugin: $repo"
  herdr plugin install "$repo" --yes
}

install_plugin "paulbkim-dev/vim-herdr-navigation"
install_plugin "qu8n/herdr-automatic-rename"

echo
echo "Installed Herdr plugins:"
herdr plugin list
