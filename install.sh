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

echo "Configuring macos variables..."

./macos/macos.sh

