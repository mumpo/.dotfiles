#!/usr/bin/env bash

select_dev_project() {
  find ~/dev -mindepth 1 -maxdepth 1 -type d | fzf --tmux 80%
}

start_dev_session() {
  local selected="$1"

  if [[ -z $selected ]]; then
    return 0
  fi

  local selected_name
  selected_name=$(basename "$selected" | tr . _)

  local window_name
  if [[ ${#selected_name} -gt 15 ]]; then
    window_name="${selected_name:0:6}...${selected_name: -6}"
  else
    window_name="$selected_name"
  fi

  tmux new-window -n "$window_name" -c "$selected" "nvim; zsh"
  tmux split-window -v -l 12 -c "#{pane_current_path}"
  tmux select-pane -t 0
  tmux resize-pane -Z
}
