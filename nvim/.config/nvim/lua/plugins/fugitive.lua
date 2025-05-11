return {
  -- Wrapper around Git commands
  "tpope/vim-fugitive",
  dependencies = {
    "tpope/vim-rhubarb",
  },
  keys = {
    { "gB", "<cmd>GBrowse<cr>", "Open in browser" },
    { "<leader>gd", "<cmd>Gvdiffsplit<cr>", "Open Git diff tool" },
  },
}
