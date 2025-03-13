return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "jay-babu/mason-nvim-dap.nvim",
    "zapling/mason-conform.nvim",
  },
  config = function()
    require("mason").setup {}

    require("mason-lspconfig").setup {
      ensure_installed = {
        "eslint",
        "lua_ls",
        "gopls",
        "ts_ls",
        "yamlls",
      },
    }

    require("mason-nvim-dap").setup {
      ensure_installed = {
        "delve", -- Debugger for go
        "js",
      },
    }

    require("mason-conform").setup()
  end,
}
