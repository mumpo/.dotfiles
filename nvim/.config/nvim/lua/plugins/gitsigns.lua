return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup {
      current_line_blame = true,

      on_attach = function(bufnr)
        local gitsigns = require "gitsigns"

        local function map(mode, l, r, desc)
          local opts = { noremap = true, silent = true, desc = desc, buffer = bufnr }
          vim.keymap.set(mode, l, r, opts)
        end

        -- Actions
        map("n", "[h", function()
          gitsigns.nav_hunk "prev"
        end, "Go to previous hunk")
        map("n", "]h", function()
          gitsigns.nav_hunk "next"
        end, "Go to next hunk")

        map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")

        map("n", "<leader>hS", gitsigns.stage_buffer, "Stage buffer")
        map("n", "<leader>hR", gitsigns.reset_buffer, "Reset buffer")
        map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
        map("n", "<leader>hi", gitsigns.preview_hunk_inline, "Inline preview hunk")

        map("n", "<leader>hb", function()
          gitsigns.blame_line { full = true }
        end, "Blame line")

        map("n", "<leader>hd", gitsigns.diffthis, "Show diff")
      end,
    }
  end,
}
