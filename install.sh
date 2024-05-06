#!/usr/bin/env bash

for d in */ ; do
    echo "stow $d"
    stow -D $d
    stow $d
done
