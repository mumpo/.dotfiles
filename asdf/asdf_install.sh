#!/bin/zsh

cut -d' ' -f1 .tool-versions | sort \
  | comm -23 - <(asdf plugin-list | sort) \
  | join -a1 - <(asdf plugin list all) \
  | xargs -t -L1 asdf plugin add

asdf reshim nodejs
