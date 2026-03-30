return {
  "sindrets/diffview.nvim",
  dependencies = "nvim-lua/plenary.nvim",
  keys = {
    { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
    { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    { "<leader>gdm", "<cmd>DiffviewOpen main<cr>", desc = "Open diffview comparing to main" },
    { "<leader>gdf", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    {
      "<leader>gdl",
      function()
        local line = vim.api.nvim_win_get_cursor(0)[1]

        -- Get blame for current line via fugitive
        local blame = vim.fn.systemlist {
          "git",
          "blame",
          "-L",
          line .. "," .. line,
          "--porcelain",
          vim.fn.expand "%",
        }

        local commit = blame[1]:match "^(%w+)"
        if commit and not commit:match "^0+$" then
          vim.cmd("DiffviewOpen " .. commit .. "^!")
        else
          vim.notify "No commit found (uncommitted line?)"
        end
      end,
      desc = "Inspect changes on current line's blame",
    },
  },
  opts = {
    enhanced_diff_hl = true,
    default = {
      winbar_info = true,
    },
    view = {
      merge_tool = {
        layout = "diff3_mixed",
      },
    },
  },
}
