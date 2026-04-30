local function set_octo_highlights()
  local bg = vim.o.background

  if bg == "dark" then
    vim.api.nvim_set_hl(0, "OctoEditable", { bg = "#1a1b26" })
    vim.api.nvim_set_hl(0, "OctoStatusColumn", { bg = "#1a1b26" })
  else
    vim.api.nvim_set_hl(0, "OctoReviewDiffDeleteText", { bg = "#cc9fa6" })
    vim.api.nvim_set_hl(0, "OctoReviewDiffAddText", { bg = "#8cb898" })
    vim.api.nvim_set_hl(0, "OctoEditable", { bg = "#ffffff" })
    vim.api.nvim_set_hl(0, "OctoStatusColumn", { fg = "#eeeeee", bg = "#ffffff" })
  end
end

set_octo_highlights()

-- Adapt to dark/light mode changes.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  callback = set_octo_highlights,
})

return {
  "pwntester/octo.nvim",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("octo").setup {
      ui = {
        use_signcolumn = true, -- Must be true for OctoEditable to work
      },
      mappings = {
        review_diff = {
          toggle_viewed = { lhs = "<leader>grf", desc = "toggle review file viewed state" },
        },
        submit_win = {
          -- Default was <C-a>, which conflicts with tmux prefix
          approve_review = { lhs = "<C-s>", desc = "approve review", mode = { "n", "i" } },
        },
      },
    }
    -- Watching this https://github.com/pwntester/octo.nvim/issues/914 for folding
    -- This one might give us hooks to do custom folding: https://github.com/pwntester/octo.nvim/issues/1249

    -- These are not editable yet
    vim.cmd [[sign define octo_clean_block_start text=█ linehl=OctoEditable]]
    vim.cmd [[sign define octo_clean_block_end text=█ linehl=OctoEditable]]
    vim.cmd [[sign define octo_clean_block_middle text=█ linehl=OctoEditable]]
    vim.cmd [[sign define octo_dirty_block_start text=█ linehl=OctoEditable]]
    vim.cmd [[sign define octo_dirty_block_end text=█ linehl=OctoEditable]]
    vim.cmd [[sign define octo_dirty_block_middle text=█ linehl=OctoEditable]]
  end,
  cmds = {
    "Octo",
  },
  keys = {
    { "<leader>gpl", "<cmd>Octo pr list<cr>", desc = "List PRs" },
    { "<leader>gpb", "<cmd>Octo pr browser<cr>", desc = "Open PR in browser" },
    { "<leader>grn", "<cmd>Octo review<cr>", desc = "New PR review" },
    { "<leader>grd", "<cmd>Octo review discard<cr>", desc = "Discard PR review" },
    { "<leader>grc", "<cmd>Octo review close<cr>", desc = "Close PR review" },
    { "<leader>grb", "<cmd>Octo review browse<cr>", desc = "Browser PR review" },
    { "<leader>grs", "<cmd>Octo review submit<cr>", desc = "Submit PR review" },
    { "<leader>gca", "<cmd>Octo comment add<cr>", desc = "Add comment" },
  },
}
