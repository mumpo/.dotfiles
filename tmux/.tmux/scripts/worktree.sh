#!/usr/bin/env bash

source ~/.tmux/utils/dev-session.sh

current_path=$(tmux display-message -p '#{pane_current_path}')

if [[ $current_path == "$HOME"/dev/* ]]; then
  repo_path=$current_path
else
  repo_path=$(select_dev_project)
  if [[ -z $repo_path ]]; then
    exit 0
  fi
fi

repo_name=$(basename "$repo_path" | tr './' '_')

read -p "Worktree name: " worktree_name

if [[ -z $worktree_name ]]; then
  exit 0
fi

worktree_name=$(echo "$worktree_name" | tr './' '_')
worktree_path=~/dev/${repo_name}.${worktree_name}

if [[ -d $worktree_path ]]; then
  echo "Error: Directory $worktree_path already exists"
  exit 1
fi

if git -C "$repo_path" worktree list | grep -q "$worktree_path"; then
  echo "Error: Worktree $worktree_path already exists"
  exit 1
fi

git -C "$repo_path" worktree add "$worktree_path"

start_dev_session "$worktree_path"
