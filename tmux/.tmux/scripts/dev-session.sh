#!/usr/bin/env bash

selected=$(find ~/dev -mindepth 1 -maxdepth 1 -type d | fzf)

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

tmux new-window -n $selected_name -c $selected "nvim; zsh"

tmux split-window -v -l 16 -c "#{pane_current_path}"
