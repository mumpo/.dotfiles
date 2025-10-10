#!/usr/bin/env bash

echo "Symlinking directories with stow..."

for d in */ ; do
    echo "stow $d"
    stow -D $d
    stow $d
done

echo "Installing dependencies with Homebrew..."

# Install Brewfile dependencies
brew bundle --file=homebrew/Brewfile

# Github CLI extensions
gh extension install dlvhdr/gh-dash

# Start skhd
skhd --start-service

# Fixing buildx in Apple Silicon
# https://gist.github.com/Aeonitis/cbd9f8b61eaec5a8a024c0a42f415ca3

# Check if /usr/local/lib/docker directory exists, create it if it doesn't
if [ ! -d "/usr/local/lib/docker" ]; then
  echo "Directory /usr/local/lib/docker does not exist. Creating..."
  mkdir -p /usr/local/lib/docker
  echo "Created directory: /usr/local/lib/docker"
else
  echo "Directory /usr/local/lib/docker already exists."
fi

# Check for Docker CLI plugins directory under /usr/local/lib
if [ -d "/usr/local/lib/docker/cli-plugins" ]; then
  echo "Docker CLI plugins directory already exists: /usr/local/lib/docker/cli-plugins"
else
  # Create symlink to Docker CLI plugins directory under /Applications
  echo "Docker CLI plugins directory does not exist. Creating symlink..."
  ln -s /Applications/Docker.app/Contents/Resources/cli-plugins /usr/local/lib/docker/cli-plugins
  echo "Symlink created: /usr/local/lib/docker/cli-plugins -> /Applications/Docker.app/Contents/Resources/cli-plugins"
fi

# Verify the symlink
if [ -L "/usr/local/lib/docker/cli-plugins" ]; then
  echo "Symlink verification: Successful"
else
  echo "Symlink verification: Failed"
fi

echo "Configuring macos variables..."

./macos/macos.sh

