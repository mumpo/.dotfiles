return {
  "projekt0n/github-nvim-theme",
  opts = {
    options = {
      transparent = true, -- Enable this to disable the background color
    },
    groups = {
      all = {
        -- Keep syntax highlighting in diffs
        DiffAdd = { fg = "NONE", bg = "diff.add" },
        DiffChange = { fg = "NONE", bg = "diff.change" },
        DiffDelete = { fg = "NONE", bg = "diff.delete" },
      },
    },
  },
  config = function(_, opts)
    require("github-theme").setup(opts)
  end,
}
