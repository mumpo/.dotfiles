local map = vim.keymap.set

local servers = {
  "lua_ls",
  "html",
  "cssls",
  "gopls",
  "jsonls",
  "ts_ls",
  "eslint",
  "yamlls",
}

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    {
      "<leader>d",
      vim.diagnostic.open_float,
      desc = "Show line diagnostics",
    },
    {
      "<leader>D",
      "<cmd>Telescope diagnostics bufnr=0<CR>",
      desc = "Show file diagnostics",
    },
  },
  config = function()
    local lspconfig = require "lspconfig"
    local cmp_nvim_lsp = require "cmp_nvim_lsp"

    local on_attach = function(_, bufnr)
      local function opts(desc)
        return { buffer = bufnr, noremap = true, silent = true, desc = "LSP " .. desc }
      end

      map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts "Show references")
      map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
      map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts "Show definitions")
      map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts "Show implementations")
      map("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts "Show type definitions")
      map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")
    end

    local capabilities = cmp_nvim_lsp.default_capabilities()

    for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
      }
    end

    lspconfig.lua_ls.setup {
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    }

    lspconfig.eslint.setup {
      settings = { format = false },
    }

    local signs = { Error = "󰅙", Warning = "", Hint = "", Information = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end
  end,
}
