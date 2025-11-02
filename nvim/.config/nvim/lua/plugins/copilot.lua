return {
  "zbirenbaum/copilot.lua",
  dependencies = {
    "copilotlsp-nvim/copilot-lsp",
  },
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = {
      auto_trigger = true,
    },
    nes = {
      enabled = true,
      keymap = {},
    },
    -- Copilot needs Node.js version > 22, so we specify the path to the Node.js binary installed via asdf
    copilot_node_command = vim.fn.expand "$HOME" .. "/.asdf/installs/nodejs/22.12.0/bin/node",
    server = {
      type = "binary",
      custom_server_filepath = vim.fn.expand "$HOME"
        .. "/.asdf/installs/nodejs/22.12.0/lib/node_modules/@github/copilot-language-server-darwin-arm64/copilot-language-server",
    },
  },
  config = function(_, opts)
    require("copilot").setup(opts)

    vim.lsp.enable "copilot_ls"

    vim.keymap.set({ "n", "i" }, "<C-n>", function()
      local cmp = require "cmp"
      if cmp.visible() then
        -- Fallback to nvim-cmp navigation if the completion menu is visible
        cmp.select_next_item()
      end

      local bufnr = vim.api.nvim_get_current_buf()
      local state = vim.b[bufnr].nes_state
      if state then
        -- Try to jump to the start of the suggestion edit.
        -- If already at the start, then apply the pending suggestion and jump to the end of the edit.
        local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
          or (require("copilot-lsp.nes").apply_pending_nes() and require("copilot-lsp.nes").walk_cursor_end_edit())
        return nil
      else
        vim.notify("No Copilot NES suggestion available", vim.log.levels.INFO)
      end
    end, { desc = "Copilot Next Edit Suggestion (NES)" })
  end,
}
