return {
  "sindrets/diffview.nvim",
  dependencies = "nvim-lua/plenary.nvim",
  keys = {
    { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
    { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    { "<leader>gdm", "<cmd>DiffviewOpen main<cr>", desc = "Open diffview comparing to main" },
    { "<leader>gdf", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
  },
}
