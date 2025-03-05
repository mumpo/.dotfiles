#!/usr/bin/env bash

selected=$(find ~/dev -mindepth 1 -maxdepth 1 -type d | fzf --tmux 80%)

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

tmux new-window -n $selected_name -c $selected "nvim; zsh"

tmux split-window -v -l 12 -c "#{pane_current_path}"

tmux select-pane -t 0
