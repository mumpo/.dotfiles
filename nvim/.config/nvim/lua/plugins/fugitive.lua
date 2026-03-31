return {
  -- Wrapper around Git commands
  "tpope/vim-fugitive",
  dependencies = {
    "tpope/vim-rhubarb",
  },
  keys = {
    { "gB", "<cmd>GBrowse<cr>", mode = "n", desc = "Open in browser" },
    { "gB", ":GBrowse<cr>", mode = "v", desc = "Open in browser" },
  },
}
