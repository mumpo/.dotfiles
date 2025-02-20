return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "bash",
      "javascript",
      "json",
      "lua",
      "markdown",
      "regex",
      "tsx",
      "typescript",
      "vim",
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
