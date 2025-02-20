return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "│" },
      untracked = { text = "│" },
      change = { text = "│" },
      delete = { text = "│" },
      topdelete = { text = "│" },
      changedelete = { text = "│" },
    },
  },
  keys = {
    { "<leader>gb", "<cmd>Gitsigns blame_line<cr>", desc = "Blame line" },
  },
  config = function(_, opts)
    require("gitsigns").setup(opts)
  end,
}
