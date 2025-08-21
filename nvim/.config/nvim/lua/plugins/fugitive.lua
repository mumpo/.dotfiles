return {
  -- Wrapper around Git commands
  "tpope/vim-fugitive",
  dependencies = {
    "tpope/vim-rhubarb",
  },
  keys = {
    { "gB", "<cmd>GBrowse<cr>", desc = "Open in browser" },
    { "<leader>gds", "<cmd>Gvdiffsplit<cr>", desc = "Diff file" },
    { "<leader>gdm", "<cmd>Gvdiffsplit main<cr>", desc = "Diff file with main" },
  },
}
