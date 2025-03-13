local function get_root_folder_name()
  local cwd = vim.fn.getcwd()
  return cwd:match "^.+/(.+)$"
end

return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      css = { "prettier" },
      html = { "prettier" },
      json = { "jq" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      go = { "gofmt", "goimports", "golines" },
    },

    formatters = {
      goimports = {
        prepend_args = { "-local", "github.com/Typeform/" .. get_root_folder_name() },
      },
    },

    format_on_save = function(bufnr)
      local skipped_formatters = {
        "jq",
        "golines",
      }

      local conform = require "conform"
      local available_formatters = conform.list_formatters_for_buffer(bufnr)

      local formatters_to_run = vim.tbl_filter(function(formatter)
        return not vim.tbl_contains(skipped_formatters, formatter)
      end, available_formatters)

      return {
        timeout_ms = 2500,
        lsp_fallback = true,
        formatters = formatters_to_run,
      }
    end,
  },
  keys = {
    {
      "<leader>fm",
      function()
        -- Get start and end positions of the selection
        local start_pos = vim.fn.getpos "'<"
        local end_pos = vim.fn.getpos "'>"

        -- Convert to 0-based indexing for Conform
        local range = {
          start = start_pos[2] - 1, -- line number (0-based)
          ["end"] = end_pos[2], -- line number (0-based, exclusive)
        }

        -- Apply formatting to the selected range
        require("conform").format { async = true, range = range }
      end,
      desc = "Format selection",
      mode = "v",
    },
  },
}
