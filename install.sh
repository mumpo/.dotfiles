#!/usr/bin/env bash

for d in */ ; do
    echo "stow $d"
    stow -D $d
    stow $d
done

# Install Brewfile dependencies
brew bundle --file=homebrew/Brewfile

# Github CLI extensions
gh extension install dlvhdr/gh-dash

./macos/macos.sh
