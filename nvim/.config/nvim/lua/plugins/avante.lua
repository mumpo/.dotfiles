return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  opts = {
    provider = "copilot",
    copilot = {
      model = "claude-3.7-sonnet",
    },
    windows = {
      sidebar_header = {
        rounded = false,
      },
      ask = {
        border = "rounded",
      },
    },
  },
}
