#!/usr/bin/env bash
claude
ec=$?

self_session=$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null || echo _scratch)
if [[ "$self_session" != "_scratch" && -n "${GHOST_PEER:-}" ]]; then
  # Claude exited while visible — swap the original pane back before dying
  tmux swap-pane -s "$TMUX_PANE" -t "$GHOST_PEER" 2>/dev/null || true
fi

exit "$ec"
