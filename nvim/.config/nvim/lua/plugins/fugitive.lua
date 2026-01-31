return {
  -- Wrapper around Git commands
  "tpope/vim-fugitive",
  dependencies = {
    "tpope/vim-rhubarb",
  },
  keys = {
    { "gB", "<cmd>GBrowse<cr>", mode = { "n", "v" }, desc = "Open in browser" },
    -- { "<leader>gds", "<cmd>Gvdiffsplit<cr>", desc = "Diff file" },
    -- { "<leader>gdm", "<cmd>Gvdiffsplit main<cr>", desc = "Diff file with main" },
  },
}
