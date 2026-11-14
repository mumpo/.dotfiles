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

echo "Installing uv tools..."
./uv-tools.sh

# Github CLI extensions
gh extension install dlvhdr/gh-dash

# Start skhd
skhd --start-service

# Install tmux-sess for session and worktree management
source tmux/.tmux/scripts/install_tmux_sess.sh

# Install herdr app and herdr-core (not available through Homebrew)
command -v hc >/dev/null 2>&1 || curl -fsSL https://releases.herdr.dev/core/install.sh | sh
[ -d /Applications/Herdr.app ] || curl -fsSL https://releases.herdr.dev/app/install.sh | sh

# Install herdr plugins
sh herdr/.config/herdr/scripts/install-plugins.sh

# Install herdr-gitview mods (git review panel; needs the Herdr app open)
[ -d herdr-app/.config/herdr-app/mods/gitview ] || curl -fsSL https://raw.githubusercontent.com/ChmaraX/herdr-gitview/main/install.sh | sh -s -- --app

# The selected layout lives in shared.json (machine state, not versioned): select it
herdr-app status >/dev/null 2>&1 && herdr-app do layout.switch --name main-nums

echo "Configuring macos variables..."

./macos/macos.sh

