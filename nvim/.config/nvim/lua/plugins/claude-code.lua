return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  opts = {
    focus_after_send = true,
    terminal = {
      provider = "external",
      provider_opts = {
        external_terminal_cmd = function(cmd, env)
          local env_args = ""
          for k, v in pairs(env) do
            env_args = env_args .. " " .. k .. "=" .. v
          end

          -- Avoid opening a second pane if Claude is already running
          local panes = vim.fn.system "tmux list-panes -F '#{pane_id} #{pane_current_command}'"
          for line in panes:gmatch "[^\n]+" do
            local pane_id, pane_cmd = line:match "^(%S+) (%S+)"
            if pane_id and pane_cmd and pane_cmd:find "claude" then
              vim.fn.system("tmux select-pane -t " .. pane_id)
              return { "true" }
            end
          end

          return { "tmux", "split-window", "-hf", "-l", "90", "env" .. env_args .. " " .. cmd }
        end,
      },
    },
  },
  keys = {
    { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude in tmux" },
    { "<leader>ct", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send this to Claude" },
    { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    -- Diff management
    { "<leader>cy", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff (Yes)" },
    { "<leader>cn", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff (No)" },
  },
}
