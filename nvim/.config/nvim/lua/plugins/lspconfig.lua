local map = vim.keymap.set

local servers = {
  "html",
  "cssls",
  "gopls",
  "jsonls",
  "ts_ls",
  "yamlls",
}

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "mrcjkb/rustaceanvim",
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
    local cmp_nvim_lsp = require "cmp_nvim_lsp"

    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Setup LspAttach autocmd for key mappings
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local bufnr = ev.buf

        local function opts(desc)
          return { buffer = bufnr, noremap = true, silent = true, desc = "LSP " .. desc }
        end

        map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts "Show references")
        map("n", "gD", vim.lsp.buf.declaration, opts "Go to declaration")
        map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts "Show definitions")
        map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts "Show implementations")
        map("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts "Show type definitions")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")

        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end,
    })

    -- Configure servers using new API
    for _, server in ipairs(servers) do
      vim.lsp.config(server, {
        capabilities = capabilities,
      })
    end

    vim.lsp.config("lua_ls", {
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    })

    vim.lsp.config("eslint", {
      capabilities = capabilities,
      settings = { format = false },
    })

    -- Enable all servers
    local all_servers = vim.list_extend(vim.deepcopy(servers), { "lua_ls", "eslint" })
    vim.lsp.enable(all_servers)

    -- Setup rustacean without on_attach since we use LspAttach now
    vim.g.rustaceanvim = {
      server = {
        capabilities = capabilities,
      },
    }

    local signs = { Error = "󰅙", Warning = "", Hint = "", Information = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end
  end,
}
