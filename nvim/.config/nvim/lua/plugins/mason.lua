return {
  "williamboman/mason.nvim",
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason").setup {
        ensure_installed = {
          "stylua",
          "jq",
          "html-lsp",
          "css-lsp",
          "prettier",
        },
      }

      require("mason-lspconfig").setup {
        ensure_installed = {
          "eslint",
          "lua_ls",
          "gopls",
          "ts_ls",
        },
      }
    end,
  },
}
