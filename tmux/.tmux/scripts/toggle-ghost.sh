#!/usr/bin/env bash
set -euo pipefail

current=$(tmux display-message -p '#{pane_id}')
peer=$(tmux show-options -p -v -q -t "$current" @ghost_peer 2>/dev/null || true)

# Lazy cleanup: peer is stale or dead
if [[ -n $peer ]]; then
  if ! tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qxF "$peer"; then
    tmux set-option -p -u -t "$current" @ghost_peer
    peer=""
  fi
fi

if [[ -z $peer ]]; then
  cwd=$(tmux display-message -p -t "$current" '#{pane_current_path}')

  if ! tmux has-session -t _scratch 2>/dev/null; then
    tmux new-session -d -s _scratch -n __init -x 220 -y 50 \
      "while :; do sleep 86400; done"
  fi

  peer=$(tmux new-window -P -d \
    -t _scratch: \
    -n "ghost-${current#%}" \
    -c "$cwd" \
    -e "GHOST_PEER=$current" \
    -F '#{pane_id}' \
    "$HOME/.tmux/utils/ghost-wrapper.sh")

  tmux set-option -p -t "$current" @ghost_peer "$peer"
  tmux set-option -p -t "$peer"    @ghost_peer "$current"
fi

tmux swap-pane -s "$current" -t "$peer"
tmux select-pane -t "$peer"
