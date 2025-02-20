return {
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  opts = {
    ensure_installed = {
      "lua-language-server",
      "stylua",
      "html-lsp",
      "css-lsp",
      "prettier",
      "gopls",
      "typescript-language-server",
    },
  },
  config = function(_, opts)
    require("mason").setup(opts)

    require("mason-lspconfig").setup {
      ensure_installed = {
        "eslint",
      },
    }
  end,
}
