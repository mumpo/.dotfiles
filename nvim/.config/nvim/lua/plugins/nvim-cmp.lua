-- Icons to use in the completion menu.
local symbol_kinds = {
  Class = "",
  Color = "",
  Constant = "",
  Constructor = "",
  Enum = "",
  EnumMember = "",
  Event = "",
  Field = "",
  File = "",
  Folder = "",
  Function = "",
  Interface = "",
  Keyword = "",
  Method = "",
  Module = "",
  Operator = "",
  Property = "",
  Reference = "",
  Snippet = "",
  Struct = "",
  Text = "",
  TypeParameter = "",
  Unit = "",
  Value = "",
  Variable = "",
}

return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        config = function()
          local luasnip = require "luasnip"
          local types = require "luasnip.util.types"

          require("luasnip.loaders.from_vscode").lazy_load()

          -- HACK: Cancel the snippet session when leaving insert mode.
          vim.api.nvim_create_autocmd("ModeChanged", {
            group = vim.api.nvim_create_augroup("UnlinkSnippetOnModeChange", { clear = true }),
            pattern = { "s:n", "i:*" },
            callback = function(event)
              if luasnip.session and luasnip.session.current_nodes[event.buf] and not luasnip.session.jump_active then
                luasnip.unlink_current()
              end
            end,
          })

          luasnip.setup {
            -- Display a cursor-like placeholder in unvisited nodes
            -- of the snippet.
            ext_opts = {
              [types.insertNode] = {
                unvisited = {
                  virt_text = { { "|", "Conceal" } },
                  virt_text_pos = "inline",
                },
              },
              [types.exitNode] = {
                unvisited = {
                  virt_text = { { "|", "Conceal" } },
                  virt_text_pos = "inline",
                },
              },
            },
          }

          local react_snippets = require "snippets.react"
          luasnip.add_snippets("typescriptreact", react_snippets)
        end,
      },
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lsp",
      "saadparwaiz1/cmp_luasnip",
      "kristijanhusak/vim-dadbod-completion",
    },
    version = false,
    event = "InsertEnter",
    config = function()
      local cmp = require "cmp"
      local luasnip = require "luasnip"

      -- Inside a snippet, use backspace to remove the placeholder.
      vim.keymap.set("s", "<BS>", "<C-O>s")

      ---@diagnostic disable: missing-fields
      cmp.setup {
        -- Disable preselect. On enter, the first thing will be used if nothing
        -- is selected.
        preselect = cmp.PreselectMode.None,
        -- Add icons to the completion menu.
        formatting = {
          format = function(_, vim_item)
            vim_item.kind = (symbol_kinds[vim_item.kind] or "") .. "  " .. vim_item.kind
            return vim_item
          end,
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          -- Make the completion menu bordered.
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        view = {
          -- Explicitly request documentation.
          -- docs = { auto_open = false },
        },
        mapping = cmp.mapping.preset.insert {
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<CR>"] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          },
          ["<C-n>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              -- Fallback to nvim-cmp navigation if the completion menu is visible
              cmp.select_next_item()
              return
            end

            local bufnr = vim.api.nvim_get_current_buf()
            local state = vim.b[bufnr].nes_state
            if state then
              -- Try to jump to the start of the suggestion edit.
              -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
              local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
                or (
                  require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit()
                )
              return nil
            else
              vim.notify("No Copilot NES suggestion available", vim.log.levels.INFO)
            end
          end),
          -- Explicitly request completions.
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          -- Overload tab to accept Copilot suggestions.
          ["<Tab>"] = cmp.mapping(function(fallback)
            local copilot = require "copilot.suggestion"

            if copilot.is_visible() then
              copilot.accept()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.expand_or_locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-d>"] = function()
            if cmp.visible_docs() then
              cmp.close_docs()
            else
              cmp.open_docs()
            end
          end,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
        }),
      }
      ---@diagnostic enable: missing-fields

      cmp.setup.filetype("sql", {
        sources = cmp.config.sources {
          { name = "vim-dadbod-completion" },
          { name = "buffer" },
        },
      })
    end,
  },
}
