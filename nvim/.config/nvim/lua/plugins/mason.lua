return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "jay-babu/mason-nvim-dap.nvim",
  },
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

    require("mason-nvim-dap").setup {
      ensure_installed = {
        "delve", -- Debugger for go
        "js",
      },
    }
  end,
}
