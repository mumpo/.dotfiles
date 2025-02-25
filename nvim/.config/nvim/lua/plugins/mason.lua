return {
  "williamboman/mason.nvim",
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason").setup {
        ensure_installed = {
          "stylua",
          "html-lsp",
          "css-lsp",
          "prettier",
          "gopls",
          "typescript-language-server",
        },
      }

      require("mason-lspconfig").setup {
        ensure_installed = {
          "eslint",
          "lua_ls",
        },
      }
    end,
  },
}
