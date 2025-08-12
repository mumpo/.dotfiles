return {
  "projekt0n/github-nvim-theme",
  opts = {
    options = {
      transparent = true, -- Enable this to disable the background color
    },
  },
  config = function(_, opts)
    require("github-theme").setup(opts)
  end,
}
