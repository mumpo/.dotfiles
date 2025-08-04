return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      win = { border = "rounded" },
      disable = {
        filetypes = { "alpha" },
      },
    },
    config = function(_, opts)
      local wk = require "which-key"
      wk.setup(opts)

      wk.add {
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "find" },
        { "<leader>h", group = "hunk" },
        { "<leader>l", group = "lazy" },
        { "<leader>r", group = "rest" },
        { "<leader>t", group = "test" },
        { "=", group = "put" },
        { "[", group = "previous" },
        { "]", group = "next" },
        { "g", group = "goto" },
      }
    end,
  },
}
