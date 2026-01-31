return {
  "folke/snacks.nvim",
  opts = {
    input = { enabled = true },
    notifier = { enabled = true },
    picker = {
      enabled = true,
      -- Replace vim.ui.select with snacks' picker
      ui_select = true,
    },
  },
  keys = {
    {
      "<leader>n",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification History",
    },
  },
}
