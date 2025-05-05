return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "bash",
      "go",
      "gomod",
      "hcl",
      "http",
      "javascript",
      "json",
      "lua",
      "markdown",
      "regex",
      "terraform",
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
