#!/usr/bin/env bash

tmux new-session -d -s main -c "$HOME/.dotfiles" -n dot "nvim; zsh"
tmux split-window -v -l 12 -c "#HOME/.dotfiles"
tmux select-pane -t 0
tmux resize-pane -Z
tmux new-window -t main:1 -c "$HOME" 
tmux select-window -t main:1
tmux attach -t main

