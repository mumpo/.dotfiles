#!/usr/bin/env bash
set -euo pipefail

project="$(
  find "$HOME/dev" -mindepth 1 -maxdepth 1 -type d |
    sort |
    fzf \
      --prompt="Project > " \
      --reverse \
      --border
)"

[[ -n "$project" ]] || exit 0

label="$(basename "$project")"
herdr="${HERDR_BIN_PATH:-herdr}"

wait_for_shell() {
  local pane_id="$1"
  local attempts=50
  local process_json

  while (( attempts > 0 )); do
    process_json="$(
      "$herdr" pane process-info --pane "$pane_id" 2>/dev/null || true
    )"

    if jq -e '
      .result.process_info as $info
      | ($info.foreground_processes | length) == 1
      and $info.foreground_processes[0].pid == $info.shell_pid
      and $info.foreground_processes[0].name == "zsh"
    ' >/dev/null 2>&1 <<<"$process_json"; then
      return 0
    fi

    sleep 0.2
    ((attempts--))
  done

  return 1
}

workspace_json="$(
  "$herdr" workspace create \
    --cwd "$project" \
    --label "$label" \
    --focus
)"

workspace_id="$(jq -r '.result.workspace.workspace_id' <<<"$workspace_json")"

# herdr plugin action invoke apply --plugin herdr-spreader 
# herdr plugin action invoke apply --plugin herdr-plugin-workspace-manager 

nvim_tab_id="$(jq -r '.result.tab.tab_id' <<<"$workspace_json")"
nvim_pane_id="$(jq -r '.result.root_pane.pane_id' <<<"$workspace_json")"

wait_for_shell "$nvim_pane_id"
"$herdr" pane run "$nvim_pane_id" "nvim"

create_tab() {
  local tab_cmd="$1"

  tab_json="$(
    "$herdr" tab create \
      --workspace "$workspace_id" \
      --cwd "$project" \
      --no-focus
  )"

  new_pane_id="$(jq -r '.result.root_pane.pane_id' <<<"$tab_json")"
  wait_for_shell "$new_pane_id"
  "$herdr" pane run "$new_pane_id" "$tab_cmd"
}

# create_tab "lazygit"
# create_tab "claude"
