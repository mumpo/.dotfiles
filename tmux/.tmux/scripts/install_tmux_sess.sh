#!/usr/bin/env bash

install_tmux_sess() (
  echo "Installing tmux-sess..."

  tmux_sess_download_dir=$(mktemp -d)
  cd "$tmux_sess_download_dir"

  gh release download -R mumpo/tmux-sess -p 'tmux-sess-*-aarch64-apple-darwin.tar.gz*'

  shasum -a 256 -c ./*.sha256
  tar -xzf ./*.tar.gz

  mkdir -p "$HOME/.local/bin"
  install -m 755 tmux-sess "$HOME/.local/bin/tmux-sess"

  echo "Installed tmux-sess successfully"
)

install_tmux_sess
