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
      -- Prevent duplicated LSP servers running
      automatic_enable = false,
      ensure_installed = {
        "eslint",
        "lua_ls",
        "jsonls",
        "rust_analyzer",
        "ts_ls",
        "yamlls",
        "html",
      },
    }

    require("mason-nvim-dap").setup {
      ensure_installed = {
        "delve", -- Debugger for go
        "js",
      },
    }

    require("mason-conform").setup {
      ignore_install = { "prettier" },
    }
  end,
}
