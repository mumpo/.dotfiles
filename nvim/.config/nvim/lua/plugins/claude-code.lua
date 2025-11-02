-- return {
--   "greggh/claude-code.nvim",
--   dependencies = {
--     "nvim-lua/plenary.nvim", -- Required for git operations
--   },
--   opts = {
--     window = {
--       position = "vsplit", -- Position of the window: "botright", "topleft", "vertical", "vsplit", etc.
--     },
--     keymaps = {
--       toggle = {
--         normal = "<leader>cc", -- Toggle Claude Code from normal mode
--       },
--     },
--   },
--   config = function(_, opts)
--     require("claude-code").setup(opts)
--   end,
-- }

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    -- { "<leader>cc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>cs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>cC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>cb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    -- Diff management
    { "<leader>cy", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff (Yes)" },
    { "<leader>cn", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff (No)" },
  },
}
