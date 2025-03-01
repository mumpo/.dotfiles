return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "bash",
      "go",
      "gomod",
      "http",
      "javascript",
      "json",
      "lua",
      "markdown",
      "regex",
      "tsx",
      "typescript",
      "vim",
    },
    highlight = {
      enable = true,
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
